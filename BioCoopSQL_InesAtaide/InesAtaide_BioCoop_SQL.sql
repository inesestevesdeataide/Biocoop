USE BioCoop_InesAtaide
GO


/************************************
*           Consultas SQL           * 
*************************************/

/*|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
||| 1. Para cada cooperativa, apresente o número total de associados. |||
|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||*/

SELECT coop.*, [ct].[Total de Associados]
FROM Cooperativa coop, 
(
    SELECT coop.Codigo, COUNT(a.Id) [Total de Associados]
    FROM Cooperativa coop
        LEFT OUTER JOIN Associado a 
        ON a.CodigoCooperativa = coop.Codigo 
    GROUP BY coop.Codigo
) [ct]
WHERE coop.Codigo = ct.Codigo

/*|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
||| 2. Para uma determinada cooperativa, liste todas as categorias que são elas próprias subcategorias, |||
||| apresentando a informação da seguinte forma.                                                        |||
|||                                                                                                     |||
||| (12) Vegetais > (21) Batatas                                                                        |||
||| (10) Vegetais > (12) Cenouras                                                                       |||
|||                                                                                                     |||
||| A listagem deve estar ordenada por categoria e subcategoria.                                        |||
||| Os números que precedem o nome da categoria representam o id.                                       |||
|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||*/

SELECT cat.CodigoCooperativa [Código da Cooperativa], CONCAT('(', r.IdParentCategoria, ') ', parent.Nome, 
    ' > (', cat.Id, ') ', cat.Nome) [(ID) Categoria > (ID) Subcategoria]
FROM Cooperativa coop 
    JOIN Categoria cat 
    ON cat.CodigoCooperativa = coop.Codigo
    JOIN Referir r 
    ON r.IdCategoria = cat.Id
    JOIN Categoria parent 
    ON parent.Id = r.IdParentCategoria
ORDER BY parent.Nome, cat.Nome, r.IdParentCategoria, cat.Id, cat.CodigoCooperativa

/* Dado o exemplo, em que ID de Vegetais 12 precede ID de Vegetais 10 (de outra cooperativa), assumi que 
não era pretendida ordenação por cooperativa. 
Para além disso, como (21) Batatas surge antes de (12) Cenouras, assumi também que a ordem pretendida era 
a alfabética e não de ID. */

/*||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
||| 3. Liste todos os clientes que já receberam mais cabazes. Se o máximo de cabazes enviados a um     |||
||| determinado cliente for 7, queremos listar todos os clientes que receberam também eles, 7 cabazes. |||
||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||*/

SELECT DISTINCT ca.IdCliente [Id do Cliente], CONCAT(c.Nome, ' ', c.Apelido) Nome, c.Email, c.NIF, 
    [ce].[# Cabazes Recebidos]
FROM Cabaz ca 
    JOIN Cliente c 
    ON ca.IdCliente = c.Id
    JOIN 
    (
        SELECT ca.IdCliente, COUNT(*) [# Cabazes Recebidos]
        FROM Cabaz ca
        GROUP BY ca.IdCliente
        HAVING COUNT(*) = 
        (
            SELECT MAX(Contador)
            FROM
            (
                SELECT COUNT(*) Contador
                FROM Cabaz ca 
                GROUP BY ca.IdCliente
                ) [mx]
        ) 
    ) [ce] 
    ON [ce].IdCliente = ca.IdCliente
ORDER BY 1

/*|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
||| 4. Liste os 10 produtos que mais vezes foram incluídos em cabazes durante o último ano. |||
|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||*/
 
SELECT TOP(10) dc.IdProduto [ID de Produto], prod.Nome Produto, COUNT(*) [# Presenças em Cabazes]
FROM DetalheCabaz dc 
    JOIN Cabaz ca 
    ON dc.IdCabaz = ca.Id
    JOIN Produto prod 
    ON prod.Id = dc.IdProduto
WHERE ca.Data > GETDATE() - 365
GROUP By dc.IdProduto, prod.Nome
ORDER BY 3 DESC

/*|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
||| 5. Crie uma consulta para apresentar o total faturado pelos clientes de cada cooperativa ao longo   |||
||| do tempo. Ordene por ordem descendente do valor faturado.                                           |||
|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||*/

SELECT coop.Codigo [Código da Cooperativa], SUM([fcp].[Faturação / Cooperativa | Plano]) 
    [Faturação Total / Cooperativa]
FROM Cooperativa coop 
    JOIN 
    (
        SELECT c.CodigoCooperativa, s.CodigoPlano, p.Preco, s.IdCliente, s.[Data],
            p.Preco * (DATEDIFF(MONTH, s.[Data], GetDate()) + 1)  [Faturação / Cooperativa | Plano]
        FROM Cliente c 
            JOIN Subscrever s 
            ON s.IdCliente = c.Id
            JOIN Plano p 
            ON p.Codigo = s.CodigoPlano
        GROUP BY c.CodigoCooperativa, s.CodigoPlano, p.Preco, s.IdCliente, s.[Data]
    )[fcp] 
    ON [fcp].CodigoCooperativa = coop.Codigo
GROUP BY coop.Codigo

/* Assume-se que a primeira fatura/pagamento é processada no momento da subscrição e as subsequentes no 
primeiro dia de cada mês. 
Considerou-se que o pretendido era o total faturado aos clientes de cada cooperativa. 
(i) Havendo a possibilidade de um cliente subscrever um plano (faturado) e ainda não ter recebido um cabaz, 
a dado momento, e 
(ii) considerando que o Preço Total do Cabaz poderá corresponder ao preço de custo do produtor por cabaz 
entregue (de acordo com a valoração que a cooperativa faz dos produtos), optou-se for calcular a faturação,
o somatório de valores cobrados/imputados ao cliente pelo serviço de que usufrui, a partir do relacionamento 
entre Cliente e Plano. 
(iii) Dado que os vários planos subscritos ao longo do tempo pelos clientes não se encontram armazenados nos
seus registos, que contêm apenas dados para o plano ativo para dado cliente, esta faturação incide meramente
nessa informação. */