-- Completa las notas de la demostración y permite recuperar la instalación que falló con 52408.
-- No borrar estudiantes, pagos o la base. No sobrescribe calificaciones existentes.
SET NOCOUNT ON; SET XACT_ABORT ON;
IF @@TRANCOUNT<>0 THROW 54902,N'Cierra transacciones antes de completar la demostración.',1;
DECLARE @Profesor nvarchar(450)=N'demo-profesor',@Tipo int,@Evaluacion int,@Clase int,
 @Version varchar(18),@VersionBinaria binary(8),@Registro nvarchar(10),@Json nvarchar(max),@i int,@Fecha date;
IF NOT EXISTS(SELECT 1 FROM dbo.AspNetUsers WHERE Id=@Profesor AND Email=N'profesor@liceo.test')
 OR NOT EXISTS(SELECT 1 FROM dbo.ControlFinanciero WHERE Id=1 AND Migrado=1)
 THROW 54902,N'Este archivo requiere las cuentas y el corte de la instalación de demostración.',1;

DECLARE @Clases TABLE(Id int PRIMARY KEY);
INSERT @Clases
 SELECT D.Id FROM dbo.AsignacionDocente D JOIN dbo.Asignatura S ON S.Id=D.AsignaturaId
 JOIN dbo.GrupoAcademico G ON G.Id=D.GrupoId
 WHERE D.UsuarioId=@Profesor AND S.Codigo IN
 (N'DEMO-1-1',N'DEMO-1-2',N'DEMO-2-1',N'DEMO-2-2',N'DEMO-3-1',N'DEMO-3-2');
IF (SELECT COUNT(*) FROM @Clases)<>6
 THROW 54902,N'No se encontraron las seis clases de demostración esperadas. No se modificaron otras clases.',1;
SELECT @Tipo=Id FROM dbo.TipoEvaluacion WHERE Nombre=N'Trabajo práctico demo';
IF @Tipo IS NULL
BEGIN
 INSERT dbo.TipoEvaluacion(Nombre) VALUES(N'Trabajo práctico demo');
 SET @Tipo=SCOPE_IDENTITY();
END;
DECLARE Clases CURSOR LOCAL FAST_FORWARD FOR SELECT Id FROM @Clases ORDER BY Id;
OPEN Clases; FETCH NEXT FROM Clases INTO @Clase;
WHILE @@FETCH_STATUS=0
BEGIN
 SELECT @Fecha=P.Inicio FROM dbo.AsignacionDocente D JOIN dbo.GrupoAcademico G ON G.Id=D.GrupoId
 JOIN dbo.PeriodoAcademico P ON P.Id=G.PeriodoId WHERE D.Id=@Clase;
 SET @i=1;
 WHILE @i<=2
 BEGIN
  SET @Evaluacion=NULL;
  SELECT @Evaluacion=Id FROM dbo.Evaluacion
   WHERE AsignacionId=@Clase AND Nombre=CONCAT(N'Evaluación demo ',@i);
  IF @Evaluacion IS NULL
  BEGIN
   SET @Json=(SELECT N'Evaluacion' Accion,@Clase AsignacionId,@Tipo TipoId,CONCAT(N'Evaluación demo ',@i) Nombre,
    @Fecha Fecha,N'Cuantitativa' Modo,100 Maximo,50 Peso FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
   EXEC dbo.Notas_Guardar @Json,@Profesor,@ResultadoId=@Evaluacion OUTPUT;
  END;
  SET @VersionBinaria=NULL; SET @Version=NULL; SET @Registro=NULL;
  SELECT @VersionBinaria=CONVERT(binary(8),E.Version)
   FROM dbo.Evaluacion E WHERE E.Id=@Evaluacion AND E.AsignacionId=@Clase;
  -- No convertir timestamp directamente a varchar: normalizar primero a ocho bytes.
  SET @Version=CONVERT(varchar(18),sys.fn_varbintohexstr(CONVERT(varbinary(8),@VersionBinaria)));
  IF @VersionBinaria IS NULL OR DATALENGTH(@Version)<>18 OR TRY_CONVERT(binary(8),@Version,1)<>@VersionBinaria
   THROW 54902,N'No se pudo representar la versión de la evaluación. No se intentó guardar una nota sin versión.',1;
  SELECT TOP(1) @Registro=A.Registro FROM dbo.GrupoEstudiante A
   JOIN dbo.AsignacionDocente D ON D.GrupoId=A.GrupoId
   JOIN dbo.Estudiantes E ON E.Registro=A.Registro
   WHERE D.Id=@Clase AND E.NombreEstudiante LIKE N'Demo %'
   ORDER BY A.Registro;
  IF @Registro IS NULL THROW 54902,N'No hay alumno demo inscrito en la clase.',1;
  IF NOT EXISTS(SELECT 1 FROM dbo.Calificacion WHERE EvaluacionId=@Evaluacion AND Registro=@Registro)
  BEGIN
   SET @Json=(SELECT N'Nota' Accion,@Clase AsignacionId,@Evaluacion EvaluacionId,@Registro Registro,
    @Version VersionEvaluacion,CAST(85 AS decimal(7,2)) Nota,N'Resultado de demostración' Observacion
    FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
   IF TRY_CONVERT(binary(8),JSON_VALUE(@Json,'$.VersionEvaluacion'),1)<>@VersionBinaria
    THROW 54902,N'La versión de la evaluación no se conservó en el formulario demo.',1;
   EXEC dbo.Notas_Guardar @Json,@Profesor;
  END;
  SET @i+=1;
 END;
 FETCH NEXT FROM Clases INTO @Clase;
END;
CLOSE Clases; DEALLOCATE Clases;
IF (SELECT COUNT(*) FROM dbo.Calificacion C JOIN dbo.Evaluacion E ON E.Id=C.EvaluacionId
 JOIN @Clases D ON D.Id=E.AsignacionId WHERE E.Nombre IN(N'Evaluación demo 1',N'Evaluación demo 2'))<12
 THROW 54902,N'Faltan calificaciones de demostración.',1;
SELECT N'DEMOSTRACIÓN COMPLETADA: cuentas, pagos y estudiantes conservados.' Resultado;
