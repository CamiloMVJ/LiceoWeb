CREATE OR ALTER PROCEDURE Mostrar_Costo_Mensualidad
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        Mensualidad_Modalidad AS Modalidad, 
        Costo_Actual AS CostoActual 
    FROM Costo_Mensualidad
    ORDER BY Mensualidad_Modalidad;
END
GO

CREATE OR ALTER PROCEDURE Actualizar_Costo_Mensualidad
    @Modalidad nvarchar(20), 
    @CostoNuevo int
AS
BEGIN
    SET NOCOUNT ON;

    IF (@CostoNuevo <= 0)
    BEGIN
        RAISERROR('El costo de la mensualidad debe ser mayor a cero.', 16, 1);
        RETURN;
    END

    UPDATE Costo_Mensualidad 
    SET Costo_Actual = @CostoNuevo 
    WHERE Mensualidad_Modalidad = @Modalidad;
END
GO