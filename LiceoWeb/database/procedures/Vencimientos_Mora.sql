CREATE OR ALTER PROCEDURE Actualizar_Estados_Vencidos
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Dia_Corte int = 17;
    DECLARE @Fecha_Actual datetime = GETDATE();
    DECLARE @Anio_Actual int = YEAR(@Fecha_Actual);
    DECLARE @Mes_Actual int = MONTH(@Fecha_Actual);
    DECLARE @Dia_Actual int = DAY(@Fecha_Actual);

    UPDATE Mensualidades 
    SET Estado = 'Vencido'
    WHERE Estado = 'Pendiente' 
      AND (
          (Anio < @Anio_Actual) OR 
          (Anio = @Anio_Actual AND Numero_Mes < @Mes_Actual) OR 
          (Anio = @Anio_Actual AND Numero_Mes = @Mes_Actual AND @Dia_Actual > @Dia_Corte)
      );
END
GO

CREATE OR ALTER PROCEDURE Actualizar_Visualizar_Mora
    @Mes_Visualizar int = NULL,
    @Anio_Visualizar int = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Primero aseguramos que los estados estén al día con la regla unificada
    EXEC Actualizar_Estados_Vencidos;

    SELECT 
        E.Registro, 
        E.NombreEstudiante AS Nombre,
        M.Modalidad, 
        E.Grado,
        M.Mes, 
        M.Numero_Mes AS NumeroMes,
        M.Anio, 
        M.Costo_Mensualidad AS CostoMensualidad, 
        M.Estado
    FROM Mensualidades M
    INNER JOIN Estudiantes E ON M.Registro_Estudiante = E.Registro
    WHERE M.Estado = 'Vencido'
      AND (@Mes_Visualizar IS NULL OR M.Numero_Mes = @Mes_Visualizar)
      AND (@Anio_Visualizar IS NULL OR M.Anio = @Anio_Visualizar)
    ORDER BY M.Anio ASC, M.Numero_Mes ASC, E.NombreEstudiante ASC;
END
GO