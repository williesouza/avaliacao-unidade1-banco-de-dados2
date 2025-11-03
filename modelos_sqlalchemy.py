import uuid
from sqlalchemy import create_engine, Column, Integer, String, DateTime, Float, Numeric, Boolean, LargeBinary, ForeignKey, SmallInteger
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship, declarative_base
from sqlalchemy.sql import func

# --- Configuração Base ---
Base = declarative_base()

# URL de conexão (exemplo para PostgreSQL)
DATABASE_URL = "postgresql://postgres:root@localhost:5432/postgres"
engine = create_engine(DATABASE_URL)

# --- Tabelas de Entidade Principal ---

class UnidadeOperacional(Base):
    __tablename__ = 'unidadeoperacional'
    __table_args__ = {'schema': 'public'}
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    qap_lot_id = Column(Integer, unique=True)
    descri = Column(String)
    sigla = Column(String)
    codigolotacao = Column(String)
    
    # Relacionamentos
    lavagens_filtro = relationship("LavagemFiltro", back_populates="unidade")
    lavagens_decantador = relationship("LavagemDecantador", back_populates="unidade")
    aplicacoes_produto = relationship("AplicacaoProdutoQuimico", back_populates="unidade")
    estoque_recebimentos = relationship("EstoqueRecebimento", back_populates="unidade")
    estoque_inventarios = relationship("EstoqueInventario", back_populates="unidade")
    
    # Relacionamentos N:N (via Association Object)
    tipos_coleta_assoc = relationship("UnidadeTipoColeta", back_populates="unidade")
    usuarios_assoc = relationship("UsuarioUnidades", back_populates="unidade")

class ProdutoQuimico(Base):
    __tablename__ = 'produtoquimico'
    __table_args__ = {'schema': 'public'}
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    id_unidade = Column(Integer)
    qap_pro_id = Column(Integer, unique=True, nullable=False)
    descricao = Column(String)
    
    # Relacionamentos
    aplicacoes = relationship("AplicacaoProdutoQuimico", back_populates="produto")
    recebimentos = relationship("EstoqueRecebimento", back_populates="produto")
    inventarios = relationship("EstoqueInventario", back_populates="produto")

class HorariosColeta(Base):
    __tablename__ = 'horarioscoleta'
    __table_args__ = {'schema': 'public'}
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    deschorario = Column(String, nullable=False)
    id_iqap_horario = Column(Integer, unique=True, nullable=False)

class Ocorrencias(Base):
    __tablename__ = 'ocorrencias'
    __table_args__ = {'schema': 'public'}
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    descricao = Column(String, nullable=False)
    id_iqap_oco = Column(Integer, unique=True, nullable=False)
    
    # Relacionamento
    monitoramentos = relationship("Monitoramento", back_populates="ocorrencia")

class TipoColeta(Base):
    __tablename__ = 'tipocoleta'
    __table_args__ = {'schema': 'public'}
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    tpc_id = Column(Integer, unique=True, nullable=False)
    tpc_descri = Column(String)
    
    # Relacionamento N:N (via Association Object)
    unidades_assoc = relationship("UnidadeTipoColeta", back_populates="tipo_coleta")


class User(Base):
    __tablename__ = 'users'
    __table_args__ = {'schema': 'auth'}
    
    id = Column(UUID(as_uuid=True), primary_key=True)
    email = Column(String)
 
    
    # Relacionamentos
    monitoramentos = relationship("Monitoramento", back_populates="usuario")
    lavagens_filtro = relationship("LavagemFiltro", back_populates="usuario")
    lavagens_decantador = relationship("LavagemDecantador", back_populates="usuario")
    aplicacoes_produto = relationship("AplicacaoProdutoQuimico", back_populates="usuario")
    estoque_recebimentos = relationship("EstoqueRecebimento", back_populates="usuario")
    estoque_inventarios = relationship("EstoqueInventario", back_populates="usuario")
    
    # Relacionamento N:N (via Association Object)
    unidades_assoc = relationship("UsuarioUnidades", back_populates="usuario")

# --- Tabelas de Eventos / Registros ---

class Monitoramento(Base):
    __tablename__ = 'monitoramentos'
    __table_args__ = {'schema': 'public'}
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now(), server_default=func.now())
    deleted = Column(Boolean, default=False)
    vazao = Column(String)
    cor = Column(String)
    turbidez = Column(String)
    ph = Column(String)
    cloro = Column(String)
    imagem = Column(LargeBinary)
    data = Column(String)
    hora = Column(String)
    operador = Column(String)
    laboratorista = Column(String)
    email = Column(String)
    ferro = Column(String)
    manganes = Column(String)
    aluminio = Column(String)
    alcalinidade = Column(String)
    fluor = Column(String)
    ocorrencia_presente = Column(Boolean, nullable=False, default=False)
    obs_ocorrencia = Column(String)
    data_coleta = Column(String)
    horario_manual = Column(String)
    
    # Chaves Estrangeiras
    usuario_id = Column(UUID(as_uuid=True), ForeignKey('auth.users.id'))
    qap_lot_id = Column(String) 
    tpc_id = Column(String)
    id_iqap_horario = Column(Integer, ForeignKey('public.horarioscoleta.id_iqap_horario'), nullable=False, default=13)
    id_iqap_oco = Column(Integer, ForeignKey('public.ocorrencias.id_iqap_oco'))
    
    # Relacionamentos
    usuario = relationship("User", back_populates="monitoramentos")
    ocorrencia = relationship("Ocorrencias", back_populates="monitoramentos")
    horario = relationship("HorariosColeta")
    

    
class AplicacaoProdutoQuimico(Base):
    __tablename__ = 'aplicacaoprodutoquimico'
    __table_args__ = {'schema': 'public'}
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    ponto_aplicacao = Column(String)
    quantidade = Column(Float)
    usuario_id = Column(UUID(as_uuid=True), ForeignKey('auth.users.id'))
    email = Column(String)
    data = Column(String)
    hora = Column(String)
    horario_manual = Column(String)
    
    # Chaves Estrangeiras
    qap_lot_id = Column(Integer, ForeignKey('public.unidadeoperacional.qap_lot_id'))
    id_iqap_horario = Column(Integer, ForeignKey('public.horarioscoleta.id_iqap_horario'))
    qap_prod_id = Column(Integer, ForeignKey('public.produtoquimico.qap_pro_id'), nullable=False)
    
    # Relacionamentos
    unidade = relationship("UnidadeOperacional", back_populates="aplicacoes_produto")
    horario = relationship("HorariosColeta")
    produto = relationship("ProdutoQuimico", back_populates="aplicacoes")
    usuario = relationship("User", back_populates="aplicacoes_produto")

class EstoqueInventario(Base):
    __tablename__ = 'estoqueinventario'
    __table_args__ = {'schema': 'public'}
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    quantidade = Column(Numeric, nullable=False)
    usuario_id = Column(UUID(as_uuid=True), ForeignKey('auth.users.id'))
    email = Column(String)
    data = Column(String)
    hora = Column(String)
    horario_manual = Column(String)

    # Chaves Estrangeiras
    qap_lot_id = Column(Integer, ForeignKey('public.unidadeoperacional.qap_lot_id'), nullable=False)
    id_iqap_horario = Column(Integer, ForeignKey('public.horarioscoleta.id_iqap_horario'), nullable=False)
    qap_prod_id = Column(Integer, ForeignKey('public.produtoquimico.qap_pro_id'), nullable=False)
    
    # Relacionamentos
    unidade = relationship("UnidadeOperacional", back_populates="estoque_inventarios")
    horario = relationship("HorariosColeta")
    produto = relationship("ProdutoQuimico", back_populates="inventarios")
    usuario = relationship("User", back_populates="estoque_inventarios")

class EstoqueRecebimento(Base):
    __tablename__ = 'estoquerecebimento'
    __table_args__ = {'schema': 'public'}
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    quantidade = Column(Numeric, nullable=False)
    usuario_id = Column(UUID(as_uuid=True), ForeignKey('auth.users.id'))
    email = Column(String)
    nota_fiscal = Column(String, nullable=False)
    lote = Column(String, nullable=False)
    data = Column(String)
    hora = Column(String)
    horario_manual = Column(String)
    
    # Chaves Estrangeiras
    qap_lot_id = Column(Integer, ForeignKey('public.unidadeoperacional.qap_lot_id'), nullable=False)
    id_iqap_horario = Column(Integer, ForeignKey('public.horarioscoleta.id_iqap_horario'), nullable=False)
    qap_prod_id = Column(Integer, ForeignKey('public.produtoquimico.qap_pro_id'), nullable=False)

    # Relacionamentos
    unidade = relationship("UnidadeOperacional", back_populates="estoque_recebimentos")
    horario = relationship("HorariosColeta")
    produto = relationship("ProdutoQuimico", back_populates="recebimentos")
    usuario = relationship("User", back_populates="estoque_recebimentos")

class LavagemDecantador(Base):
    __tablename__ = 'lavagemdecantador'
    __table_args__ = {'schema': 'public'}
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    data = Column(String, nullable=False)
    hora = Column(String, nullable=False)
    numero_decantador = Column(Integer, nullable=False)
    tempo_lavagem = Column(String, nullable=False)
    volume_utilizado = Column(Numeric, nullable=False)
    obs = Column(String)
    usuario_id = Column(UUID(as_uuid=True), ForeignKey('auth.users.id'))
    email = Column(String)
    tipo = Column(String)
    horario_manual = Column(String)

    # Chaves Estrangeiras
    qap_lot_id = Column(Integer, ForeignKey('public.unidadeoperacional.qap_lot_id'), nullable=False)
    id_iqap_horario = Column(Integer, ForeignKey('public.horarioscoleta.id_iqap_horario'), nullable=False)
    
    # Relacionamentos
    unidade = relationship("UnidadeOperacional", back_populates="lavagens_decantador")
    horario = relationship("HorariosColeta")
    usuario = relationship("User", back_populates="lavagens_decantador")
    
class LavagemFiltro(Base):
    __tablename__ = 'lavagemfiltro'
    __table_args__ = {'schema': 'public'}
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    data = Column(String, nullable=False)
    hora = Column(String, nullable=False)
    numero_filtro = Column(Integer, nullable=False)
    tempo_lavagem = Column(String, nullable=False)
    volume_utilizado = Column(Numeric, nullable=False)
    obs = Column(String)
    usuario_id = Column(UUID(as_uuid=True), ForeignKey('auth.users.id'))
    email = Column(String)
    horario_manual = Column(String)
    
    # Chaves Estrangeiras
    qap_lot_id = Column(Integer, ForeignKey('public.unidadeoperacional.qap_lot_id'), nullable=False)
    id_iqap_horario = Column(Integer, ForeignKey('public.horarioscoleta.id_iqap_horario'), nullable=False)

    # Relacionamentos
    unidade = relationship("UnidadeOperacional", back_populates="lavagens_filtro")
    horario = relationship("HorariosColeta")
    usuario = relationship("User", back_populates="lavagens_filtro")
    
# --- Tabelas de Associação (N:N) ---

class UnidadeTipoColeta(Base):
    __tablename__ = 'unidadetipocoleta'
    __table_args__ = {'schema': 'public'}
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    ativo = Column(SmallInteger)

    # Chaves Estrangeiras
    qap_lot_id = Column(Integer, ForeignKey('public.unidadeoperacional.qap_lot_id'))
    qap_tpc_id = Column(Integer, ForeignKey('public.tipocoleta.tpc_id'))
    
    # Relacionamentos
    unidade = relationship("UnidadeOperacional", back_populates="tipos_coleta_assoc")
    tipo_coleta = relationship("TipoColeta", back_populates="unidades_assoc")

class UsuarioUnidades(Base):
    __tablename__ = 'usuariounidades'
    __table_args__ = {'schema': 'public'}
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    usr_codigo = Column(Integer, nullable=False)
    email = Column(String)

    # Chaves Estrangeiras
    qap_lot_id = Column(Integer, ForeignKey('public.unidadeoperacional.qap_lot_id'), nullable=False)
    id_supabase = Column(UUID(as_uuid=True), ForeignKey('auth.users.id'))
    
    # Relacionamentos
    unidade = relationship("UnidadeOperacional", back_populates="usuarios_assoc")
    usuario = relationship("User", back_populates="unidades_assoc")

# --- Criação das tabelas (opcional, se não existirem) ---
if __name__ == "__main__":

    Base.metadata.create_all(engine)
    print("Modelos SQLAlchemy sincronizados com o banco de dados.")