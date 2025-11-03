-- =================================================================
-- Arquivo: sql/01_stored_procedures.sql
-- Descrição: Contém as 4 Stored Procedures (Funções) solicitadas.
-- ATUALIZADO para o schema local (sem 'auth' ou 'supabase')
-- =================================================================

/**
 * SP 1: Obter Monitoramentos por Unidade Operacional
 *
 * Retorna todos os registros de monitoramento para uma qap_lot_id específica.
 * (Esta SP não precisou de alterações, pois não dependia do schema 'auth')
 *
 * @param p_qap_lot_id - O ID da unidade operacional (lotação).
 * @return SETOF public.monitoramentos - Uma tabela com os registros encontrados.
 */
CREATE OR REPLACE FUNCTION public.sp_get_monitoramentos_por_unidade(
    p_qap_lot_id integer
)
RETURNS SETOF public.monitoramentos AS $$
BEGIN
    RETURN QUERY
    SELECT *
    FROM public.monitoramentos
    WHERE qap_lot_id = p_qap_lot_id::text;
END;
$$ LANGUAGE plpgsql;

-- Exemplo de uso:
-- SELECT * FROM public.sp_get_monitoramentos_por_unidade(123);

-------------------------------------------------------------------

/**
 * SP 2: Registrar Recebimento de Estoque
 *
 * Insere um novo registro de recebimento de produto químico no estoque.
 *
 * @param p_qap_lot_id - ID da unidade (lotação).
 * @param p_id_iqap_horario - ID do horário da coleta.
 * @param p_qap_prod_id - ID do produto químico.
 * @param p_quantidade - Quantidade recebida (numérico).
 * @param p_nota_fiscal - Texto da nota fiscal.
 * @param p_lote - Texto do lote.
 * @param p_usuario_id - UUID do usuário (agora da tabela 'public.usuarios').
 * @param p_email - Email do usuário (para registro).
 * @param p_data - Texto da data (ex: '2025-11-03').
 * @param p_hora - Texto da hora (ex: '09:00').
 * @return public.estoquerecebimento - O registro completo que foi inserido, ou NULL se falhar.
 */
CREATE OR REPLACE FUNCTION public.sp_registrar_recebimento_estoque(
    p_qap_lot_id integer,
    p_id_iqap_horario integer,
    p_qap_prod_id integer,
    p_quantidade numeric,
    p_nota_fiscal text,
    p_lote text,
    p_usuario_id uuid,
    p_email text,
    p_data text,
    p_hora text
)
RETURNS public.estoquerecebimento AS $$
DECLARE
    novo_recebimento public.estoquerecebimento;
BEGIN
    INSERT INTO public.estoquerecebimento (
        qap_lot_id, id_iqap_horario, qap_prod_id, quantidade, 
        nota_fiscal, lote, usuario_id, email, data, hora
    )
    VALUES (
        p_qap_lot_id, p_id_iqap_horario, p_qap_prod_id, p_quantidade,
        p_nota_fiscal, p_lote, p_usuario_id, p_email, p_data, p_hora
    )
    RETURNING * INTO novo_recebimento;
    
    RETURN novo_recebimento;

EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Falha ao registrar recebimento: %', SQLERRM;
        RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Exemplo de uso:
/*
-- (Primeiro, garanta que o UUID do usuário exista na tabela 'public.usuarios')
-- INSERT INTO public.usuarios (email) VALUES ('usuario@teste.com');
-- SELECT * FROM public.sp_registrar_recebimento_estoque(
--     123, 13, 10, 500.50, 'NF-12345', 'LOTE-ABC', 
--     (SELECT id FROM public.usuarios WHERE email = 'usuario@teste.com'), 
--     'usuario@teste.com', '2025-11-03', '08:00'
-- );
*/

-------------------------------------------------------------------

/**
 * SP 3: Obter Inventário por Produto e Unidade
 *
 * Retorna os registros de inventário de um produto específico
 * em uma unidade específica, ordenados pelo mais recente.
 * (Esta SP não precisou de alterações)
 *
 * @param p_qap_prod_id - ID do produto químico.
 * @param p_qap_lot_id - ID da unidade (lotação).
 * @return SETOF public.estoqueinventario - Uma tabela com os registros encontrados.
 */
CREATE OR REPLACE FUNCTION public.sp_get_inventario_por_produto_unidade(
    p_qap_prod_id integer,
    p_qap_lot_id integer
)
RETURNS SETOF public.estoqueinventario AS $$
BEGIN
    RETURN QUERY
    SELECT *
    FROM public.estoqueinventario
    WHERE qap_prod_id = p_qap_prod_id
      AND qap_lot_id = p_qap_lot_id
    ORDER BY created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- Exemplo de uso:
-- SELECT * FROM public.sp_get_inventario_por_produto_unidade(10, 123);

-------------------------------------------------------------------

/**
 * SP 4: Vincular Usuário a uma Unidade Operacional
 *
 * Insere um registro na tabela de associação 'usuariounidades'.
 *
 * @param p_usuario_id - UUID do usuário (da tabela 'public.usuarios').
 * @param p_qap_lot_id - ID da unidade (lotação).
 * @param p_usr_codigo - Código interno do usuário.
 * @param p_email - Email do usuário.
 * @return public.usuariounidades - O registro do vínculo criado, ou NULL se falhar.
 */
CREATE OR REPLACE FUNCTION public.sp_vincular_usuario_unidade(
    p_usuario_id uuid, -- Parâmetro renomeado (era p_id_supabase)
    p_qap_lot_id integer,
    p_usr_codigo integer,
    p_email character varying
)
RETURNS public.usuariounidades AS $$
DECLARE
    novo_vinculo public.usuariounidades;
BEGIN
    INSERT INTO public.usuariounidades (
        id_supabase, -- O nome da COLUNA no schema refatorado ainda é 'id_supabase'
        qap_lot_id, 
        usr_codigo, 
        email
    )
    VALUES (
        p_usuario_id, -- Mas ela recebe o PARÂMETRO 'p_usuario_id'
        p_qap_lot_id, 
        p_usr_codigo, 
        p_email
    )
    RETURNING * INTO novo_vinculo;
    
    RETURN novo_vinculo;

EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Falha ao vincular usuário à unidade: %', SQLERRM;
        RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Exemplo de uso:
/*
-- (Primeiro, garanta que o UUID do usuário exista na tabela 'public.usuarios')
-- INSERT INTO public.usuarios (email) VALUES ('usuario2@teste.com');
-- SELECT * FROM public.sp_vincular_usuario_unidade(
--     (SELECT id FROM public.usuarios WHERE email = 'usuario2@teste.com'), 
--     123, 999, 'usuario2@teste.com'
-- );
*/