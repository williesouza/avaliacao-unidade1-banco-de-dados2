/*
 * =================================================================
 * SCRIPT DE SCHEMA BASE - Refatorado para pgAdmin Local
 * =================================================================
 * - Remove esquemas 'auth' e 'extensions'
 * - Adiciona uma tabela 'public.usuarios' para substituir 'auth.users'
 * - Corrige todas as dependências de UUIDs
 * - Remove todos os 'GRANT' e 'PUBLICATION' específicos do Supabase
 * =================================================================
*/

-- 1. HABILITAR EXTENSÕES BÁSICAS (no esquema padrão 'public')
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "unaccent";

-- 2. FUNÇÃO DE TIMESTAMP (Sintaxe corrigida)
CREATE OR REPLACE FUNCTION public.handle_times() RETURNS trigger
    AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        NEW.created_at := now();
        NEW.updated_at := now();
    ELSIF (TG_OP = 'UPDATE') THEN
        NEW.updated_at := now();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. TABELA DE USUÁRIOS (Substituindo 'auth.users')
-- Esta tabela é necessária para as Foreign Keys funcionarem
CREATE TABLE IF NOT EXISTS public.usuarios (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    email text UNIQUE NOT NULL,
    created_at timestamptz DEFAULT now()
);

-- 4. CRIAÇÃO DAS TABELAS DO PROJETO

CREATE TABLE IF NOT EXISTS public.aplicacaoprodutoquimico (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    qap_lot_id integer,
    id_iqap_horario integer,
    ponto_aplicacao text,
    quantidade double precision,
    qap_prod_id integer NOT NULL,
    usuario_id uuid, -- Corrigido
    email text,
    data text,
    hora text,
    horario_manual text
);

CREATE TABLE IF NOT EXISTS public.estoqueinventario (
    id uuid DEFAULT uuid_generate_v4() NOT NULL, -- Corrigido
    created_at timestamp with time zone DEFAULT now(),
    qap_lot_id integer NOT NULL,
    id_iqap_horario integer NOT NULL,
    quantidade numeric NOT NULL,
    qap_prod_id integer NOT NULL,
    usuario_id uuid, -- Corrigido
    email text,
    data text,
    hora text,
    horario_manual text
);

CREATE TABLE IF NOT EXISTS public.estoquerecebimento (
    id uuid DEFAULT uuid_generate_v4() NOT NULL, -- Corrigido
    created_at timestamp with time zone DEFAULT now(),
    qap_lot_id integer NOT NULL,
    id_iqap_horario integer NOT NULL,
    quantidade numeric NOT NULL,
    qap_prod_id integer NOT NULL,
    usuario_id uuid, -- Corrigido
    email text,
    nota_fiscal text NOT NULL,
    lote text NOT NULL,
    data text,
    hora text,
    horario_manual text
);

CREATE TABLE IF NOT EXISTS public.horarioscoleta (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    deschorario text NOT NULL,
    id_iqap_horario integer NOT NULL
);

CREATE TABLE IF NOT EXISTS public.lavagemdecantador (
    id uuid DEFAULT uuid_generate_v4() NOT NULL, -- Corrigido
    created_at timestamp with time zone DEFAULT (now() AT TIME ZONE 'utc'::text),
    data text NOT NULL,
    hora text NOT NULL,
    qap_lot_id integer NOT NULL,
    id_iqap_horario integer NOT NULL,
    numero_decantador integer NOT NULL,
    tempo_lavagem text NOT NULL,
    volume_utilizado numeric NOT NULL,
    obs text,
    usuario_id uuid, -- Corrigido
    email text,
    tipo text,
    horario_manual text
);

CREATE TABLE IF NOT EXISTS public.lavagemfiltro (
    id uuid DEFAULT uuid_generate_v4() NOT NULL, -- Corrigido
    created_at timestamp with time zone DEFAULT now(),
    data text NOT NULL,
    hora text NOT NULL,
    qap_lot_id integer NOT NULL,
    id_iqap_horario integer NOT NULL,
    numero_filtro integer NOT NULL,
    tempo_lavagem text NOT NULL,
    volume_utilizado numeric NOT NULL,
    obs text,
    usuario_id uuid, -- Corrigido
    email text,
    horario_manual text
);

CREATE TABLE IF NOT EXISTS public.monitoramentos (
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    deleted boolean DEFAULT false,
    vazao text,
    cor text,
    turbidez text,
    ph text,
    cloro text,
    imagem bytea,
    data text,
    hora text,
    operador text,
    laboratorista text,
    usuario_id uuid, -- Corrigido
    qap_lot_id text,
    tpc_id text,
    email text,
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    id_iqap_horario integer DEFAULT 13 NOT NULL,
    id_iqap_oco integer,
    ferro text,
    manganes text,
    aluminio text,
    alcalinidade text,
    fluor text,
    ocorrencia_presente boolean DEFAULT false NOT NULL,
    obs_ocorrencia text,
    data_coleta text,
    horario_manual text
);

CREATE TABLE IF NOT EXISTS public.ocorrencias (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    descricao text NOT NULL,
    id_iqap_oco integer NOT NULL
);

CREATE TABLE IF NOT EXISTS public.produtoquimico (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    id_unidade integer,
    qap_pro_id integer NOT NULL,
    descricao text
);

CREATE TABLE IF NOT EXISTS public.tipocoleta (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    tpc_id integer NOT NULL,
    tpc_descri text
);

CREATE TABLE IF NOT EXISTS public.unidadeoperacional (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    qap_lot_id integer,
    descri text,
    sigla text,
    codigolotacao text
);

CREATE TABLE IF NOT EXISTS public.unidadetipocoleta (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    qap_lot_id integer,
    qap_tpc_id integer,
    ativo smallint
);

CREATE TABLE IF NOT EXISTS public.usuariounidades (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    qap_lot_id integer NOT NULL,
    usr_codigo integer NOT NULL,
    email character varying,
    id_supabase uuid -- Corrigido (agora é id_usuario)
);

-- 5. DEFINIÇÃO DE CHAVES E ÍNDICES

-- Primary Keys
ALTER TABLE ONLY public.aplicacaoprodutoquimico ADD CONSTRAINT aplicacaoprodutoquimico_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.estoqueinventario ADD CONSTRAINT estoqueinventario_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.estoquerecebimento ADD CONSTRAINT estoquerecebimento_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.horarioscoleta ADD CONSTRAINT horarioscoleta_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.lavagemdecantador ADD CONSTRAINT lavagemdecantador_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.lavagemfiltro ADD CONSTRAINT lavagemfiltro_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.monitoramentos ADD CONSTRAINT monitoramentos_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.ocorrencias ADD CONSTRAINT ocorrencias_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.produtoquimico ADD CONSTRAINT produtoquimico_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.tipocoleta ADD CONSTRAINT tipocoleta_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.unidadeoperacional ADD CONSTRAINT unidadeoperacional_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.unidadetipocoleta ADD CONSTRAINT unidadetipocoleta_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.usuariounidades ADD CONSTRAINT usuariounidades_pkey PRIMARY KEY (id);


-- Unique Keys
ALTER TABLE ONLY public.horarioscoleta ADD CONSTRAINT horarioscoleta_id_iqap_horario_key UNIQUE (id_iqap_horario);
ALTER TABLE ONLY public.monitoramentos ADD CONSTRAINT monitoramentos_id_key UNIQUE (id);
ALTER TABLE ONLY public.ocorrencias ADD CONSTRAINT ocorrencias_id_iqap_oco_key UNIQUE (id_iqap_oco);
ALTER TABLE ONLY public.produtoquimico ADD CONSTRAINT produtoquimico_qap_pro_id_key UNIQUE (qap_pro_id);
ALTER TABLE ONLY public.tipocoleta ADD CONSTRAINT tipocoleta_tpc_id_key UNIQUE (tpc_id);
ALTER TABLE ONLY public.unidadeoperacional ADD CONSTRAINT unidadeoperacional_id_iqap_key UNIQUE (qap_lot_id);

-- Indexes
CREATE INDEX idx_estoqueinventario_email ON public.estoqueinventario USING btree (email);
CREATE INDEX idx_estoqueinventario_qap_lot_id ON public.estoqueinventario USING btree (qap_lot_id);
CREATE INDEX idx_estoqueinventario_qap_prod_id ON public.estoqueinventario USING btree (qap_prod_id);
CREATE INDEX idx_estoquerecebimento_email ON public.estoquerecebimento USING btree (email);
CREATE INDEX idx_estoquerecebimento_lote ON public.estoquerecebimento USING btree (lote);
CREATE INDEX idx_estoquerecebimento_nota_fiscal ON public.estoquerecebimento USING btree (nota_fiscal);
CREATE INDEX idx_estoquerecebimento_qap_lot_id ON public.estoquerecebimento USING btree (qap_lot_id);
CREATE INDEX idx_estoquerecebimento_qap_prod_id ON public.estoquerecebimento USING btree (qap_prod_id);

-- Foreign Keys
ALTER TABLE ONLY public.aplicacaoprodutoquimico ADD CONSTRAINT aplicacaoprodutoquimico_id_iqap_horario_fkey FOREIGN KEY (id_iqap_horario) REFERENCES public.horarioscoleta(id_iqap_horario);
ALTER TABLE ONLY public.aplicacaoprodutoquimico ADD CONSTRAINT aplicacaoprodutoquimico_qap_lot_id_fkey FOREIGN KEY (qap_lot_id) REFERENCES public.unidadeoperacional(qap_lot_id);
ALTER TABLE ONLY public.aplicacaoprodutoquimico ADD CONSTRAINT aplicacaoprodutoquimico_qap_prod_id_fkey FOREIGN KEY (qap_prod_id) REFERENCES public.produtoquimico(qap_pro_id);
ALTER TABLE ONLY public.aplicacaoprodutoquimico ADD CONSTRAINT aplicacaoprodutoquimico_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id);

ALTER TABLE ONLY public.estoqueinventario ADD CONSTRAINT estoqueinventario_id_iqap_horario_fkey FOREIGN KEY (id_iqap_horario) REFERENCES public.horarioscoleta(id_iqap_horario) ON DELETE RESTRICT;
ALTER TABLE ONLY public.estoqueinventario ADD CONSTRAINT estoqueinventario_qap_lot_id_fkey FOREIGN KEY (qap_lot_id) REFERENCES public.unidadeoperacional(qap_lot_id) ON DELETE RESTRICT;
ALTER TABLE ONLY public.estoqueinventario ADD CONSTRAINT estoqueinventario_qap_prod_id_fkey FOREIGN KEY (qap_prod_id) REFERENCES public.produtoquimico(qap_pro_id) ON DELETE RESTRICT;
ALTER TABLE ONLY public.estoqueinventario ADD CONSTRAINT estoqueinventario_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.estoquerecebimento ADD CONSTRAINT estoquerecebimento_id_iqap_horario_fkey FOREIGN KEY (id_iqap_horario) REFERENCES public.horarioscoleta(id_iqap_horario) ON DELETE RESTRICT;
ALTER TABLE ONLY public.estoquerecebimento ADD CONSTRAINT estoquerecebimento_qap_lot_id_fkey FOREIGN KEY (qap_lot_id) REFERENCES public.unidadeoperacional(qap_lot_id) ON DELETE RESTRICT;
ALTER TABLE ONLY public.estoquerecebimento ADD CONSTRAINT estoquerecebimento_qap_prod_id_fkey FOREIGN KEY (qap_prod_id) REFERENCES public.produtoquimico(qap_pro_id) ON DELETE RESTRICT;
ALTER TABLE ONLY public.estoquerecebimento ADD CONSTRAINT estoquerecebimento_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.lavagemdecantador ADD CONSTRAINT lavagemdecantador_id_iqap_horario_fkey FOREIGN KEY (id_iqap_horario) REFERENCES public.horarioscoleta(id_iqap_horario) ON DELETE RESTRICT;
ALTER TABLE ONLY public.lavagemdecantador ADD CONSTRAINT lavagemdecantador_qap_lot_id_fkey FOREIGN KEY (qap_lot_id) REFERENCES public.unidadeoperacional(qap_lot_id) ON DELETE RESTRICT;
ALTER TABLE ONLY public.lavagemdecantador ADD CONSTRAINT lavagemdecantador_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.lavagemfiltro ADD CONSTRAINT lavagemfiltro_id_iqap_horario_fkey FOREIGN KEY (id_iqap_horario) REFERENCES public.horarioscoleta(id_iqap_horario) ON DELETE RESTRICT;
ALTER TABLE ONLY public.lavagemfiltro ADD CONSTRAINT lavagemfiltro_qap_lot_id_fkey FOREIGN KEY (qap_lot_id) REFERENCES public.unidadeoperacional(qap_lot_id) ON DELETE RESTRICT;
ALTER TABLE ONLY public.lavagemfiltro ADD CONSTRAINT lavagemfiltro_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.monitoramentos ADD CONSTRAINT monitoramentos_id_iqap_horario_fkey FOREIGN KEY (id_iqap_horario) REFERENCES public.horarioscoleta(id_iqap_horario);
ALTER TABLE ONLY public.monitoramentos ADD CONSTRAINT monitoramentos_id_iqap_oco_fkey FOREIGN KEY (id_iqap_oco) REFERENCES public.ocorrencias(id_iqap_oco);
ALTER TABLE ONLY public.monitoramentos ADD CONSTRAINT monitoramentos_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.unidadetipocoleta ADD CONSTRAINT unidadetipocoleta_qap_lot_id_fkey FOREIGN KEY (qap_lot_id) REFERENCES public.unidadeoperacional(qap_lot_id);
ALTER TABLE ONLY public.unidadetipocoleta ADD CONSTRAINT unidadetipocoleta_qap_tpc_id_fkey FOREIGN KEY (qap_tpc_id) REFERENCES public.tipocoleta(tpc_id);

ALTER TABLE ONLY public.usuariounidades ADD CONSTRAINT usuariounidades_id_supabase_fkey FOREIGN KEY (id_supabase) REFERENCES public.usuarios(id);
ALTER TABLE ONLY public.usuariounidades ADD CONSTRAINT usuariounidades_qap_lot_id_fkey FOREIGN KEY (qap_lot_id) REFERENCES public.unidadeoperacional(qap_lot_id);

-- FIM DO SCRIPT --