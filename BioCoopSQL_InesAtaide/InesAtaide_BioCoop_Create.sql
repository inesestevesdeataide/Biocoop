USE master
GO

IF NOT EXISTS (
    SELECT [name]
        FROM sys.databases
        WHERE [name] = N'BioCoop_InesAtaide'
)

CREATE DATABASE BioCoop_InesAtaide
GO

USE BioCoop_InesAtaide
GO


/*****************************************
*           Criação de Tabelas           * 
*****************************************/

DROP TABLE IF EXISTS Associar
DROP TABLE IF EXISTS Autorizar
DROP TABLE IF EXISTS Referir
DROP TABLE IF EXISTS Subscrever
DROP TABLE IF EXISTS TelefoneCliente
DROP TABLE IF EXISTS HistoricoPreco
DROP TABLE IF EXISTS DetalheCabaz
DROP TABLE IF EXISTS Cabaz
DROP TABLE IF EXISTS Produto
DROP TABLE IF EXISTS Categoria
DROP TABLE IF EXISTS Associado
DROP TABLE IF EXISTS Plano
DROP TABLE IF EXISTS Cliente
DROP TABLE IF EXISTS Cooperativa


CREATE TABLE Cooperativa (
    Codigo INT IDENTITY (1, 1),
    Nome VARCHAR(100) NOT NULL,
    Email VARCHAR(200) NOT NULL,
    NIF VARCHAR (10) NOT NULL,
    Telefone VARCHAR (10) NOT NULL,
    CoordWhat3 VARCHAR(100) NOT NULL,

    CONSTRAINT PK_Cooperativa PRIMARY KEY (Codigo),
    CONSTRAINT CHK_Cooperativa_Email CHECK (Email LIKE '%_@%_._%'),
    CONSTRAINT CHK_Cooperativa_CoordWhat3 CHECK (CoordWhat3 LIKE '///%_.%_.%_'),
    CONSTRAINT UN_Cooperariva_Nome UNIQUE (Nome),
    CONSTRAINT UN_Cooperariva_NIF UNIQUE (NIF)
)
GO 

CREATE TABLE Categoria (
    Id INT IDENTITY (1, 1),
    Nome VARCHAR(50) NOT NULL,
    CodigoCooperativa INT NOT NULL,

    CONSTRAINT PK_Categoria PRIMARY KEY (Id),
    CONSTRAINT FK_Categoria_CodigoCooperativa FOREIGN KEY (CodigoCooperativa) REFERENCES Cooperativa(Codigo),  
)
GO

CREATE TABLE Referir (
    IdCategoria INT NOT NULL, 
    IdParentCategoria INT NOT NULL,

    CONSTRAINT PK_Referir PRIMARY KEY (IdCategoria),
    CONSTRAINT FK_Referir_IdCategoria FOREIGN KEY (IdCategoria) REFERENCES Categoria(Id),
    CONSTRAINT FK_Referir_IdParentCategoria FOREIGN KEY (IdParentCategoria) REFERENCES Categoria(Id)
)
GO

CREATE TABLE Produto (
    Id INT IDENTITY (1, 1),
    Nome VARCHAR(50) NOT NULL,
    PrecoAtual NUMERIC (5,2) NOT NULL,
    Unidade VARCHAR(30) NOT NULL,
    IdCategoria INT NOT NULL,
    CodigoCooperativa INT NOT NULL,

    CONSTRAINT PK_Produto PRIMARY KEY (Id),
    CONSTRAINT FK_Produto_IdCategoria FOREIGN KEY (IdCategoria) REFERENCES Categoria(Id),
    CONSTRAINT FK_Produto_CodigoCooperativa FOREIGN KEY (CodigoCooperativa) REFERENCES Cooperativa(Codigo),
    CONSTRAINT CHK_Produto_Unidade CHECK (Unidade IN ('unidade', 'kg', 'l', 'm²'))
)
GO

CREATE TABLE HistoricoPreco (
    Id INT IDENTITY (1, 1),
    Preco NUMERIC(5,2) NOT NULL,
    DataInicio DATE NOT NULL,
    DataFim DATE NOT NULL,
    -- Assumindo histórico no sentido de conter apenas preços que já não estão em vigor.
    IdProduto INT NOT NULL,

    CONSTRAINT PK_HistoricoPreco PRIMARY KEY (Id),
    CONSTRAINT FK_HistoricoPreco_IdProduto FOREIGN KEY (IdProduto) REFERENCES Produto(Id)
)
GO 

CREATE TABLE Associado (
    Id INT IDENTITY (1, 1),
    Nome NVARCHAR(100) NOT NULL,
    Telefone VARCHAR(10) NOT NULL,
    NIF VARCHAR (10) NOT NULL,
    CodigoCooperativa INT NOT NULL,

    CONSTRAINT PK_Associado PRIMARY KEY (Id),
    CONSTRAINT FK_Associado_CodigoCooperativa FOREIGN KEY (CodigoCooperativa) REFERENCES Cooperativa(Codigo),
    CONSTRAINT UN_Associado_NIF UNIQUE (NIF)
)
GO

CREATE TABLE Autorizar (
    IdAssociado INT NOT NULL,
    IdProduto INT NOT NULL,
    Data DATETIME2(0) NOT NULL,
    IsBlocked BIT NOT NULL,

    CONSTRAINT PK_Autorizar PRIMARY KEY (IdAssociado, IdProduto),
    CONSTRAINT FK_Autorizar_IdAssociado FOREIGN KEY (IdAssociado) REFERENCES Associado(Id),
    CONSTRAINT FK_Autorizar_IdProduto FOREIGN KEY (IdProduto) REFERENCES Produto(Id),

)
GO

CREATE TABLE Plano (
    Codigo INT IDENTITY (1, 1),
    Nome VARCHAR(100) NOT NULL,
    Preco NUMERIC (6,2) NOT NULL,
    Descricao VARCHAR(512) NOT NULL, 
    Ativo BIT NOT NULL,

    CONSTRAINT PK_Plano PRIMARY KEY (Codigo)
)
GO

CREATE TABLE Cliente (
    Id INT IDENTITY (1, 1),
    Nome NVARCHAR(50) NOT NULL,
    Apelido NVARCHAR(50) NOT NULL,
    Email VARCHAR(200) NOT NULL,
    Sexo CHAR(1) NOT NULL,
    NIF VARCHAR (10) NOT NULL,
    CoordWhat3 VARCHAR(100) NOT NULL,
    CodigoCooperativa INT NOT NULL,

    CONSTRAINT PK_Cliente PRIMARY KEY (Id),
    CONSTRAINT FK_Cliente_CodigoCooperativa FOREIGN KEY (CodigoCooperativa) REFERENCES Cooperativa(Codigo),
    CONSTRAINT CHK_Cliente_Email CHECK (Email LIKE '%_@%_._%'),
    CONSTRAINT CHK_Cliente_Sexo CHECK (Sexo IN ('F', 'M')),
    CONSTRAINT CHK_Cliente_CoordWhat3 CHECK (CoordWhat3 LIKE '///%_.%_.%_'),
    CONSTRAINT UN_Cliente_NIF UNIQUE (NIF)
)
GO

CREATE TABLE Subscrever (
    IdCliente INT NOT NULL,
    Data DATE NOT NULL,
    CodigoPlano INT NOT NULL,
    
    CONSTRAINT PK_Subscrever PRIMARY KEY (IdCliente),
    CONSTRAINT FK_Subscrever_IdCliente FOREIGN KEY (IdCliente) REFERENCES Cliente(Id),
    CONSTRAINT FK_Subscrever_CodigoPlano FOREIGN KEY (CodigoPlano) REFERENCES Plano(Codigo)
)
GO

CREATE TABLE TelefoneCliente (
    IdCliente INT NOT NULL,
    Telefone VARCHAR(10) NOT NULL,

    CONSTRAINT PK_TelefoneCliente PRIMARY KEY (IdCliente, Telefone),
    CONSTRAINT FK_TelefoneCliente_IdCliente FOREIGN KEY (IdCliente) REFERENCES Cliente(Id)
)
GO

CREATE TABLE Associar (
    IdCliente INT NOT NULL,
    IdAssociado INT NOT NULL,
    Data DATE NOT NULL,
    Motivo VARCHAR(256) NOT NULL CONSTRAINT DF_Associar_Motivo DEFAULT 'Porque quis.',
    Ativo BIT NOT NULL,

    CONSTRAINT PK_Associar PRIMARY KEY (IdCliente, IdAssociado),
    CONSTRAINT FK_Associar_IdCliente FOREIGN KEY (IdCliente) REFERENCES Cliente(Id),
    CONSTRAINT FK_Associar_IdAssociado FOREIGN KEY (IdAssociado) REFERENCES Associado(Id)
)
GO

CREATE TABLE Cabaz (
    Id INT IDENTITY (1, 1),
    Data DATETIME2(0) NOT NULL CONSTRAINT DF_Cabaz_Data DEFAULT GetDate(),
    PrecoTotal NUMERIC (5,2) NOT NULL,
    IdAssociado INT NOT NULL,
    CodigoPlano INT NOT NULL,
    IdCliente INT NOT NULL,

    CONSTRAINT PK_Cabaz PRIMARY KEY (Id),
    CONSTRAINT FK_Cabaz_IdAssociado FOREIGN KEY (IdAssociado) REFERENCES Associado(Id),
    CONSTRAINT FK_Cabaz_CodigoPlano FOREIGN KEY (CodigoPlano) REFERENCES Plano(Codigo),
    CONSTRAINT FK_Cabaz_IdCliente FOREIGN KEY (IdCliente) REFERENCES Cliente(Id)
)
GO 

CREATE TABLE DetalheCabaz (
    Id INT IDENTITY (1, 1),
    PrecoUnit NUMERIC (5,2) NOT NULL,
    Qtd TINYINT NOT NULL,
    Preco NUMERIC (6,2) NOT NULL,
    IdCabaz INT NOT NULL,
    IdProduto INT NOT NULL,

    CONSTRAINT PK_DetalheCabaz PRIMARY KEY (Id),
    CONSTRAINT FK_DetalheCabaz_IdCabaz FOREIGN KEY (IdCabaz) REFERENCES Cabaz(Id),
    CONSTRAINT FK_DetalheCabaz_IdProduto FOREIGN KEY (IdProduto) REFERENCES Produto(Id)
)
GO


/*******************************************************
*           Índices para Chaves Estrangeiras           * 
*******************************************************/

DROP INDEX IF EXISTS IDX_Categoria_CodigoCooperativa ON Categoria
DROP INDEX IF EXISTS IDX_Referir_IdCategoria ON Referir
DROP INDEX IF EXISTS IDX_Referir_IdParentCategoria ON Referir
DROP INDEX IF EXISTS IDX_Produto_IdCategoria ON Produto 
DROP INDEX IF EXISTS IDX_Produto_CodigoCooperativa ON Produto 
DROP INDEX IF EXISTS IDX_HistoricoPreco_IdProduto ON HistoricoPreco
DROP INDEX IF EXISTS IDX_Associado_CodigoCooperativa ON Associado
DROP INDEX IF EXISTS IDX_Autorizar_IdAssociado ON Autorizar
DROP INDEX IF EXISTS IDX_Autorizar_IdProduto ON Autorizar
DROP INDEX IF EXISTS IDX_Cliente_CodigoCooperativa ON Cliente
DROP INDEX IF EXISTS IDX_Subscrever_IdCliente ON Subscrever
DROP INDEX IF EXISTS IDX_Subscrever_CodigoPlano ON Subscrever
DROP INDEX IF EXISTS IDX_TelefoneCliente_IdCliente ON TelefoneCliente
DROP INDEX IF EXISTS IDX_Associar_IdCliente ON Associar 
DROP INDEX IF EXISTS IDX_Associar_IdAssociado ON Associar
DROP INDEX IF EXISTS IDX_Cabaz_IdAssociado ON Cabaz
DROP INDEX IF EXISTS IDX_Cabaz_CodigoPlano ON Cabaz
DROP INDEX IF EXISTS IDX_Cabaz_IdCliente ON Cabaz
DROP INDEX IF EXISTS IDX_DetalheCabaz_IdCabaz ON DetalheCabaz
DROP INDEX IF EXISTS IDX_DetalheCabaz_IdProduto ON DetalheCabaz

CREATE NONCLUSTERED INDEX IDX_Categoria_CodigoCooperativa ON Categoria (CodigoCooperativa)
CREATE NONCLUSTERED INDEX IDX_Referir_IdCategoria ON Referir (IdCategoria)
CREATE NONCLUSTERED INDEX IDX_Referir_IdParentCategoria ON Referir (IdParentCategoria)
CREATE NONCLUSTERED INDEX IDX_Produto_IdCategoria ON Produto (IdCategoria)
CREATE NONCLUSTERED INDEX IDX_Produto_CodigoCooperativa ON Produto (CodigoCooperativa)
CREATE NONCLUSTERED INDEX IDX_HistoricoPreco_IdProduto ON HistoricoPreco (IdProduto)
CREATE NONCLUSTERED INDEX IDX_Associado_CodigoCooperativa ON Associado (CodigoCooperativa)
CREATE NONCLUSTERED INDEX IDX_Autorizar_IdAssociado ON Autorizar (IdAssociado)
CREATE NONCLUSTERED INDEX IDX_Autorizar_IdProduto ON Autorizar (IdProduto)
CREATE NONCLUSTERED INDEX IDX_Cliente_CodigoCooperativa ON Cliente (CodigoCooperativa)
CREATE NONCLUSTERED INDEX IDX_Subscrever_IdCliente ON Subscrever (IdCliente)
CREATE NONCLUSTERED INDEX IDX_Subscrever_CodigoPlano ON Subscrever (CodigoPlano)
CREATE NONCLUSTERED INDEX IDX_TelefoneCliente_IdCliente ON TelefoneCliente (IdCliente)
CREATE NONCLUSTERED INDEX IDX_Associar_IdCliente ON Associar (IdCliente)
CREATE NONCLUSTERED INDEX IDX_Associar_IdAssociado ON Associar (IdAssociado)
CREATE NONCLUSTERED INDEX IDX_Cabaz_IdAssociado ON Cabaz (IdAssociado)
CREATE NONCLUSTERED INDEX IDX_Cabaz_CodigoPlano ON Cabaz (CodigoPlano)
CREATE NONCLUSTERED INDEX IDX_Cabaz_IdCliente ON Cabaz (IdCliente)
CREATE NONCLUSTERED INDEX IDX_DetalheCabaz_IdCabaz ON DetalheCabaz (IdCabaz)
CREATE NONCLUSTERED INDEX IDX_DetalheCabaz_IdProduto ON DetalheCabaz (IdProduto)


/******************************************************
*           Diagrama do Modelo Físico da BD           * 
******************************************************/

/* Disponível em 
https://github.com/inesestevesdeataide/whatever/blob/main/InesAtaide_BioCoop_ModeloFIsicoBD.pdf. */