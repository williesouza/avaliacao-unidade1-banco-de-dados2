-- =================================================================
-- Arquivo: sql/02_triggers.sql
-- Descrição: Contém os 3 triggers (e suas funções) solicitados.
-- =================================================================

-- TRIGER 1: Atualizar created_at/updated_at em 'monitoramentos'
-- (Utiliza a função 'handle_times' já criada no 00_schema_base.sql)
-- =================================================================

CREATE TRIGGER trg_monitoramentos_times
BEFORE INSERT OR UPDATE ON public.monitoramentos
FOR EACH ROW
EXECUTE FUNCTION public.handle_times();

-------------------------------------------------------------------

-- TRIGER 2: Validar quantidade positiva no recebimento de estoque
-- =================================================================

-- FUNÇÃO do Trigger 2:
CREATE OR REPLACE FUNCTION public.fn_check_positive_quantity()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.quantidade <= 0 THEN
        RAISE EXCEPTION 'A quantidade recebida deve ser maior que zero. Valor informado: %', NEW.quantidade;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- TRIGGER 2:
CREATE TRIGGER trg_check_rec_quantity
BEFORE INSERT ON public.estoquerecebimento
FOR EACH ROW
EXECUTE FUNCTION public.fn_check_positive_quantity();

-------------------------------------------------------------------

-- TRIGER 3: Log (Aviso) de Lavagem de Filtro
-- =================================================================

-- FUNÇÃO do Trigger 3:
CREATE OR REPLACE FUNCTION public.fn_log_lavagem_filtro()
RETURNS TRIGGER AS $$
BEGIN
    RAISE NOTICE '[LOG DE LAVAGEM] Filtro % foi lavado na unidade % em % às %.', 
                 NEW.numero_filtro, 
                 NEW.qap_lot_id,
                 NEW.data,
                 NEW.hora;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- TRIGGER 3:
CREATE TRIGGER trg_log_lavagem
AFTER INSERT ON public.lavagemfiltro
FOR EACH ROW
EXECUTE FUNCTION public.fn_log_lavagem_filtro();