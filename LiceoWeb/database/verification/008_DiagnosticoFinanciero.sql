-- Diagnóstico de solo lectura. Ejecutar en copia de desarrollo sin cobros concurrentes.
-- No migra ni modifica importes. No equivale a una conciliación aprobada.
USE LiceoWeb_Dev;
GO
SET NOCOUNT ON;
IF OBJECT_ID('dbo.Historial_Comprobantes','U') IS NULL
 THROW 52700,N'Instale la etapa 003 antes del diagnóstico.',1;

SELECT Registro_Estudiante,Concepto,IdOrigen,Anio,Importe,Estado,Id_Comprobante
INTO #Obligaciones
FROM (
 SELECT Registro_Estudiante,N'Mensualidad' Concepto,Id IdOrigen,Anio,Costo_Mensualidad Importe,Estado,Id_Comprobante FROM dbo.Mensualidades
 UNION ALL SELECT Registro_Estudiante,N'Mantenimiento',Id,Anio,Costo_Mantenimiento,Estado,Id_Comprobante FROM dbo.Mantenimientos
 UNION ALL SELECT Registro_Estudiante,N'Evaluaciones, Boletín y Tarjeta',Id,Anio,Costo_EvBoTa,Estado,Id_Comprobante FROM dbo.EvBoTaS
 UNION ALL SELECT Registro_Estudiante,N'Promoción',Id,Anio,Costo_Promocion,Estado,Id_Comprobante FROM dbo.Promociones
) O;

-- 1. Resumen de obligaciones registradas. No genera cuotas ausentes.
WITH Deuda AS (
 SELECT Registro_Estudiante,SUM(CASE WHEN Estado IN ('Pendiente','Vencido') THEN Importe ELSE 0 END) DeudaRegistrada
 FROM #Obligaciones GROUP BY Registro_Estudiante
), Saldo AS (
 SELECT Registro_Estudiante,SUM(Abono_Disponible) SaldoFavor,COUNT(*) FilasSaldo FROM dbo.Abonos GROUP BY Registro_Estudiante
), Pago AS (
 SELECT P.Registro_Estudiante,COUNT(*) Pagos,
 SUM(CASE WHEN H.Id_Comprobante IS NULL THEN 1 ELSE 0 END) PagosSinHistorial,
 SUM(CASE WHEN H.Id_Comprobante IS NOT NULL THEN H.DineroRecibido-H.CambioDevuelto ELSE 0 END) IngresoNetoConHistorial
 FROM dbo.Pagos P LEFT JOIN dbo.Historial_Comprobantes H ON H.Id_Comprobante=P.Id_Comprobante
 GROUP BY P.Registro_Estudiante
)
SELECT E.Registro,E.NombreEstudiante,E.Estado,
 ISNULL(D.DeudaRegistrada,0) DeudaRegistrada,ISNULL(S.SaldoFavor,0) SaldoFavor,
 ISNULL(S.FilasSaldo,0) FilasSaldo,ISNULL(P.Pagos,0) Pagos,
 ISNULL(P.PagosSinHistorial,0) PagosSinHistorial,
 ISNULL(P.IngresoNetoConHistorial,0) IngresoNetoConHistorial
FROM dbo.Estudiantes E LEFT JOIN Deuda D ON D.Registro_Estudiante=E.Registro
LEFT JOIN Saldo S ON S.Registro_Estudiante=E.Registro LEFT JOIN Pago P ON P.Registro_Estudiante=E.Registro
ORDER BY E.Registro;

-- 2. Obligaciones detalladas. Cancelado sin recibo puede ser beca: revisar, no cobrar automáticamente.
SELECT O.*,CASE
 WHEN O.Importe<0 THEN N'IMPORTE_NEGATIVO'
 WHEN O.Estado='Cancelado' AND O.Id_Comprobante IS NULL THEN N'REVISAR_BECA_O_CANCELACION'
 WHEN O.Estado IN ('Pendiente','Vencido') AND O.Id_Comprobante IS NOT NULL THEN N'PENDIENTE_CON_COMPROBANTE'
 WHEN O.Id_Comprobante IS NOT NULL AND P.Id_Comprobante IS NULL THEN N'COMPROBANTE_INEXISTENTE'
 WHEN P.Registro_Estudiante<>O.Registro_Estudiante THEN N'COMPROBANTE_DE_OTRO_ESTUDIANTE'
 ELSE N'SIN_ALERTA_ESTRUCTURAL' END Revision
FROM #Obligaciones O LEFT JOIN dbo.Pagos P ON P.Id_Comprobante=O.Id_Comprobante
ORDER BY O.Registro_Estudiante,O.Anio,O.Concepto,O.IdOrigen;

-- 3. Pagos: Monto heredado no se interpreta como ingreso sin respaldo.
SELECT P.Id_Comprobante,P.Registro_Estudiante,P.Fecha_Pago,P.Concepto,P.Monto MontoHeredado,
 H.DineroRecibido,H.CambioDevuelto,H.SaldoAnterior,H.SaldoUtilizado,H.DeudaCancelada,H.SaldoFinal,
 CASE WHEN H.Id_Comprobante IS NULL THEN N'SIN_HISTORIAL: CONCILIAR'
 WHEN H.SaldoAnterior+H.DineroRecibido<>H.DeudaCancelada+H.CambioDevuelto+H.SaldoFinal THEN N'BALANCE_INCONSISTENTE'
 WHEN P.Monto<>H.DineroRecibido-H.CambioDevuelto THEN N'MONTO_DIFIERE_DEL_INGRESO_NETO'
 ELSE N'BALANCE_CON_HISTORIAL' END Revision
FROM dbo.Pagos P LEFT JOIN dbo.Historial_Comprobantes H ON H.Id_Comprobante=P.Id_Comprobante
ORDER BY P.Fecha_Pago,P.Id_Comprobante;

-- 4. Matrículas se revisan por separado: no son cuotas pendientes.
SELECT M.Id,M.Registro_Estudiante,M.Anio,M.Modalidad,M.Grado,M.Costo_Matricula,M.Id_Comprobante,
 CASE WHEN P.Id_Comprobante IS NULL THEN N'COMPROBANTE_INEXISTENTE'
 WHEN P.Registro_Estudiante<>M.Registro_Estudiante THEN N'COMPROBANTE_DE_OTRO_ESTUDIANTE'
 ELSE N'REVISAR_CON_RECIBO' END Revision
FROM dbo.Matriculas M LEFT JOIN dbo.Pagos P ON P.Id_Comprobante=M.Id_Comprobante;

-- 5. Tarifas actuales no deben reemplazar importes históricos de obligaciones.
SELECT N'Matrícula' Concepto,Matricula_Modalidad Modalidad,Costo_Actual FROM dbo.Costo_Matricula
UNION ALL SELECT N'Mensualidad',Mensualidad_Modalidad,Costo_Actual FROM dbo.Costo_Mensualidad
UNION ALL SELECT N'Mantenimiento',Mantenimiento_Modalidad,Costo_Actual FROM dbo.Costo_Mantenimiento
UNION ALL SELECT N'Evaluaciones, Boletín y Tarjeta',EvBoTa_Modalidad,Costo_Actual FROM dbo.Costo_EvBoTa
UNION ALL SELECT N'Promoción',Promocion_Modalidad,Costo_Actual FROM dbo.Costo_Promocion;

DROP TABLE #Obligaciones;
