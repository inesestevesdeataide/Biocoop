USE BioCoop_InesAtaide
GO


/****************************************
*           Criação de Vistas           * 
****************************************/

/*|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
||| 1. Crie a vista v_totalClientes para o atributo derivado TotalClientes da tabela Associado. |||
|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||*/

CREATE OR ALTER VIEW v_totalClientes 
AS 
    SELECT a.*, [ct].[Total de Clientes]
    FROM Associado a, 
    (
        SELECT a.Id, COUNT(ass.IdCliente) [Total de Clientes]
        FROM Associado a 
        LEFT OUTER JOIN Associar ass 
        ON ass.IdAssociado = a.Id 
        GROUP BY a.Id 
    ) [ct]
    WHERE a.Id = ct.Id
GO

SELECT * FROM v_totalClientes
ORDER BY 1
GO 

/*||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
||| 2. Crie uma vista que apresente informação sobre os clientes que se registaram nos últimos 30 dias,  ||| 
||| incluindo também a cooperativa, e em que associado. Ordene por cooperativa, associado e cliente, por |||
||| essa mesma ordem.                                                                                    |||
||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||*/

CREATE OR ALTER VIEW v_infoClientesUltimosTrintaDias 
AS
    SELECT coop.Codigo [Código de Cooperativa], coop.Nome Cooperativa, a.Id [ID de Associado], a.Nome 
        Associado, c.Id [ID de Cliente Registado nos Últimos 30 Dias], CONCAT(c.Nome, ' ', c.Apelido) 
        'Nome do Cliente', ass.[Data] 'Data de Associação', c.Email, c.NIF
    FROM Cooperativa coop 
        JOIN Cliente c 
        ON c.CodigoCooperativa = coop.Codigo 
        JOIN Associar ass 
        ON ass.IdCliente = c.Id 
        JOIN Associado a 
        ON a.Id = ass.IdAssociado 
    WHERE [Data] > GETDATE() - 30
GO 

SELECT * FROM v_infoClientesUltimos30Dias
ORDER BY 1, 3, 5
GO 

/*|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
||| 3. Crie uma vista para listar todos os clientes que já subscreveram um plano, mas que nunca receberam |||
||| nenhum cabaz.                                                                                         |||
|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||*/

CREATE OR ALTER VIEW v_subscritoresQueNuncaReceberamCabaz
AS 
    SELECT s.IdCliente [ID do Cliente Sem Entregas], CONCAT(c.Nome, ' ', c.Apelido) [Nome do Cliente], 
        c.Email, c.NIF, s.Data [Data de Subscrição]
    FROM Subscrever s 
        LEFT JOIN Cliente c 
        ON c.Id  = s.IdCliente 
        LEFT JOIN Cabaz ca 
        ON ca.IdCliente = c.Id 
    WHERE ca.IdCliente IS NULL
GO 

SELECT * FROM v_subscritoresQueNuncaReceberamCabaz
ORDER BY 1
GO 

/*|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
||| 4. Crie uma vista para listar, para cada plano e cooperativa, o número de clientes atualmente ativos. |||
|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||*/

CREATE OR ALTER VIEW v_clientesAtivosPorPlanoECooperativa
AS 
    SELECT s.CodigoPlano [Código de Plano], p.Nome Plano, coop.Codigo [Código de Cooperativa], coop.Nome 
        Cooperativa, COUNT(s.IdCliente) [Número de Clientes Ativos]
    FROM Cliente c 
        JOIN Subscrever s 
        ON s.IdCliente = c.Id 
        JOIN Cooperativa coop 
        ON coop.Codigo = c.CodigoCooperativa
        JOIN Plano p 
        ON p.Codigo = s.CodigoPlano 
    GROUP BY coop.Codigo, s.CodigoPlano, p.Nome, coop.Nome
GO

SELECT * FROM v_clientesAtivosPorPlanoECooperativa
ORDER BY 1, 3
GO

/* Uma vez que as cláusulas ORDER BY são inválidas em vistas e subqueries, optou-se por incluir neste script o 
SELECT statement que permite a apresentação das vistas nas ordens pretendidas. */