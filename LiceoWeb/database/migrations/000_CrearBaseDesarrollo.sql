-- Ejecutar en SSMS conectado a la instancia de desarrollo.
USE master;
GO
IF DB_ID(N'LiceoWeb_Dev') IS NULL
    EXEC(N'CREATE DATABASE [LiceoWeb_Dev]');
GO
SELECT name FROM sys.databases WHERE name = N'LiceoWeb_Dev';
