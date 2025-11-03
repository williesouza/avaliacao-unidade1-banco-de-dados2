# --- Arquivo: teste_projeto.py ---

import uuid
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
from modelos_sqlalchemy import (
    Base, UnidadeOperacional, ProdutoQuimico, HorariosColeta, 
    EstoqueRecebimento, LavagemFiltro, Monitoramento
)

# -----------------------------------------------------------------
# IMPORTANTE: Use a MESMA string de conexão que você
# colocou em 'modelos_sqlalchemy.py'
# -----------------------------------------------------------------
DATABASE_URL = "postgresql://postgres:root@localhost:5432/postgres" 

try:
    engine = create_engine(DATABASE_URL)
    SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    session = SessionLocal()
    print("✅ SUCESSO: Conexão com o banco de dados estabelecida.")
except Exception as e:
    print(f"❌ FALHA: Não foi possível conectar ao banco. Verifique sua DATABASE_URL.")
    print(e)
    exit()

# --- Preparação: Inserir dados base ---
# Precisamos inserir dados nas tabelas "pai" para evitar erros de Chave Estrangeira
try:
    print("\n--- Fase 1: Inserindo dados de dependência ---")
    
    # Usamos 'merge' para não dar erro se o dado já existir
    unidade = session.merge(UnidadeOperacional(qap_lot_id=101, descri="Unidade Teste"))
    produto = session.merge(ProdutoQuimico(qap_pro_id=901, descricao="Produto Teste"))
    horario = session.merge(HorariosColeta(id_iqap_horario=99, deschorario="Horario Teste"))
    
    session.commit()
    print("   Dados de Unidade, Produto e Horário inseridos.")
except Exception as e:
    print(f"❌ FALHA na Fase 1: {e}")
    session.rollback()
    exit()


# --- Teste 1: Validar Trigger 2 (trg_check_rec_quantity) ---
print("\n--- Fase 2: Testando Trigger 2 (Quantidade Negativa) ---")
try:
    recebimento_falho = EstoqueRecebimento(
        qap_lot_id=101, id_iqap_horario=99, qap_prod_id=901,
        quantidade=-50,  # <- Valor inválido
        nota_fiscal="123", lote="ABC"
    )
    session.add(recebimento_falho)
    session.commit()
    
    # Se o código chegar aqui, o trigger falhou
    print("❌ FALHA: O Trigger 2 NÃO impediu a inserção de quantidade negativa.")
    
except Exception as e:
    # Se entrar no 'except', o trigger funcionou!
    print("✅ SUCESSO: O Trigger 2 (fn_check_positive_quantity) funcionou.")
    print("   O banco de dados rejeitou a inserção com a mensagem esperada.")
    session.rollback() # Desfaz a transação falha


# --- Teste 2: Validar Trigger 3 (trg_log_lavagem) ---
print("\n--- Fase 3: Testando Trigger 3 (Log de Lavagem) ---")
print("   (Atenção: Verifique o console 'Notices' do seu pgAdmin ou Supabase)")
try:
    lavagem = LavagemFiltro(
        data="2025-11-03", hora="09:00", qap_lot_id=101, 
        id_iqap_horario=99, numero_filtro=5, tempo_lavagem="10 min",
        volume_utilizado=150.0
    )
    session.add(lavagem)
    session.commit()
    print("✅ SUCESSO: Lavagem de filtro inserida.")
    print("   Verifique se a mensagem '[LOG DE LAVAGEM]' apareceu no seu cliente SQL.")
except Exception as e:
    print(f"❌ FALHA: Não foi possível inserir a lavagem de filtro: {e}")
    session.rollback()


# --- Teste 3: Validar Trigger 1 (trg_monitoramentos_times) ---
print("\n--- Fase 4: Testando Trigger 1 (Timestamps) ---")
try:
    monitor = Monitoramento(
        qap_lot_id="101", # Lembre-se que esta coluna é 'text' no schema
        id_iqap_horario=99, 
        vazao="100", cor="0.5"
    )
    session.add(monitor)
    session.commit()
    
    print(f"✅ SUCESSO: Monitoramento inserido.")
    print(f"   Timestamp 'created_at' (pelo Trigger): {monitor.created_at}")
    if monitor.created_at is None:
        print("❌ FALHA: O Trigger 1 (handle_times) não preencheu o 'created_at'.")
        
except Exception as e:
    print(f"❌ FALHA: Não foi possível inserir o monitoramento: {e}")
    session.rollback()


# --- Teste 4: Validar Stored Procedures (SP 1 e SP 3) ---
print("\n--- Fase 5: Testando Stored Procedures ---")
try:
    # Testando SP 1 (sp_get_monitoramentos_por_unidade)
    print("   Testando sp_get_monitoramentos_por_unidade(101)...")
    sp_call_1 = text("SELECT * FROM public.sp_get_monitoramentos_por_unidade(:id_unidade)")
    resultado_sp1 = session.execute(sp_call_1, {"id_unidade": 101}).fetchall()
    
    if len(resultado_sp1) > 0 and resultado_sp1[0].vazao == "100":
        print(f"✅ SUCESSO: SP 1 encontrou {len(resultado_sp1)} monitoramento(s).")
    else:
        print(f"❌ FALHA: SP 1 não retornou o monitoramento esperado.")
        
    # Testando SP 3 (sp_get_inventario_por_produto_unidade)
    print("   Testando sp_get_inventario_por_produto_unidade(901, 101)...")
    sp_call_3 = text("SELECT * FROM public.sp_get_inventario_por_produto_unidade(:id_prod, :id_unid)")
    resultado_sp3 = session.execute(sp_call_3, {"id_prod": 901, "id_unid": 101}).fetchall()
    
    print(f"✅ SUCESSO: SP 3 executada (retornou {len(resultado_sp3)} registros).")

except Exception as e:
    print(f"❌ FALHA: Erro ao executar Stored Procedures: {e}")
    session.rollback()

finally:
    # Limpa os dados de teste para poder rodar o script de novo
    print("\n--- Fase 6: Limpando dados de teste ---")
    try:
        session.query(Monitoramento).filter_by(qap_lot_id="101").delete()
        session.query(LavagemFiltro).filter_by(qap_lot_id=101).delete()
        
        # (Não precisamos deletar o 'recebimento_falho' pois ele falhou)
        
        session.commit()
        print("   Dados de Monitoramento e LavagemFiltro limpos.")
    except Exception as e:
        print(f"   Aviso: Falha ao limpar dados de teste: {e}")
        session.rollback()
        
    session.close()
    print("\n--- Testes Concluídos ---")