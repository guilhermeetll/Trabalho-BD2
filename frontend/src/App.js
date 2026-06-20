import React, { useState, useEffect, useCallback } from 'react';
import { 
  Database, 
  ShieldAlert, 
  RefreshCw, 
  Package, 
  Terminal, 
  User, 
  CheckCircle2, 
  XCircle, 
  AlertCircle, 
  Calendar, 
  MapPin, 
  Layers
} from 'lucide-react';

function App() {
  const [dbStatus, setDbStatus] = useState(null);
  const [products, setProducts] = useState([]);
  const [logs, setLogs] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [refreshing, setRefreshing] = useState(false);

  const fetchData = useCallback(async () => {
    try {
      setError(null);
      
      // Chamar os endpoints do backend Python (rodando em http://localhost:8000)
      const backendUrl = process.env.REACT_APP_BACKEND_URL || 'http://localhost:8000';
      
      const [statusRes, productsRes, logsRes] = await Promise.all([
        fetch(`${backendUrl}/db-status`).then(res => {
          if (!res.ok) throw new Error('Falha ao obter status do banco');
          return res.json();
        }),
        fetch(`${backendUrl}/produtos`).then(res => {
          if (!res.ok) throw new Error('Falha ao obter lista de produtos');
          return res.json();
        }),
        fetch(`${backendUrl}/logs`).then(res => {
          if (!res.ok) throw new Error('Falha ao obter logs de auditoria');
          return res.json();
        })
      ]);

      setDbStatus(statusRes);
      setProducts(productsRes);
      setLogs(logsRes);
    } catch (err) {
      console.error(err);
      setError(err.message || 'Erro ao conectar ao servidor backend.');
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }, []);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  const handleRefresh = () => {
    setRefreshing(true);
    fetchData();
  };

  const getLogLevelClass = (event) => {
    if (!event) return 'level-info';
    const ev = event.toUpperCase();
    if (ev.includes('BLOQUEADO') || ev.includes('FALHA') || ev.includes('ERRO')) return 'level-danger';
    if (ev.includes('ALTERACAO') || ev.includes('ATUALIZACAO')) return 'level-warning';
    if (ev.includes('SUCESSO') || ev.includes('INICIALIZADO') || ev.includes('PAGO')) return 'level-success';
    return 'level-info';
  };

  const formatPrice = (value) => {
    return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(value);
  };

  const formatDateTime = (isoString) => {
    if (!isoString) return '';
    const date = new Date(isoString);
    return date.toLocaleString('pt-BR');
  };

  const renderLogDetails = (log) => {
    if (log.detalhes) {
      return <div className="log-details">{log.detalhes}</div>;
    }
    
    if (log.dados_antigos || log.dados_novos) {
      const changes = [];
      const oldVal = log.dados_antigos || {};
      const newVal = log.dados_novos || {};
      
      if (log.tabela_afetada === 'produtos') {
        const prodName = newVal.nome || oldVal.nome;
        if (oldVal.preco !== newVal.preco && newVal.preco !== undefined) {
          changes.push(`Preço de '${prodName}' alterado de R$ ${oldVal.preco} para R$ ${newVal.preco}`);
        }
        if (oldVal.estoque !== newVal.estoque && newVal.estoque !== undefined) {
          changes.push(`Estoque de '${prodName}' alterado de ${oldVal.estoque} para ${newVal.estoque}`);
        }
        if (log.evento === 'DELETE') {
          changes.push(`Produto removido do catálogo: '${oldVal.nome}'`);
        }
      }
      
      if (changes.length === 0) {
        changes.push(`Registro atualizado na tabela [${log.tabela_afetada}]`);
      }
      
      return (
        <div className="log-details" style={{ fontSize: '0.85rem' }}>
          {changes.map((change, idx) => (
            <p key={idx} style={{ marginBottom: '0.25rem' }}>• {change}</p>
          ))}
          <div style={{ 
            marginTop: '0.5rem', 
            fontSize: '0.75rem', 
            fontFamily: 'var(--font-mono)', 
            background: 'rgba(0, 0, 0, 0.25)', 
            padding: '0.5rem', 
            borderRadius: '6px', 
            overflowX: 'auto',
            border: '1px solid var(--border-color)',
            color: 'var(--text-secondary)'
          }}>
            {log.dados_antigos && <div style={{ color: 'var(--color-rose)' }}>- OLD: {JSON.stringify(log.dados_antigos)}</div>}
            {log.dados_novos && <div style={{ color: 'var(--color-emerald)', marginTop: '0.25rem' }}>+ NEW: {JSON.stringify(log.dados_novos)}</div>}
          </div>
        </div>
      );
    }
    
    return null;
  };


  return (
    <div className="app-container">
      {/* Header */}
      <header className="app-header">
        <div className="brand-section">
          <h1>E-Commerce Security & Auditoria</h1>
          <p>Painel de Segurança e Monitoramento de Banco de Dados — Disciplina BD II (UFES)</p>
        </div>
        <div>
          {error ? (
            <span className="badge badge-disconnected animate-pulse">
              <XCircle size={16} /> Banco Offline
            </span>
          ) : (
            <span className="badge badge-connected">
              <CheckCircle2 size={16} /> Banco Online
            </span>
          )}
        </div>
      </header>

      {/* Main Content */}
      {loading ? (
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', minHeight: '300px', gap: '1rem' }}>
          <div className="loading-spinner"></div>
          <p style={{ color: 'var(--text-secondary)' }}>Carregando dados da aplicação...</p>
        </div>
      ) : error ? (
        <div className="panel" style={{ borderLeft: '4px solid var(--color-rose)', marginBottom: '2rem' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', color: 'var(--color-rose)' }}>
            <AlertCircle size={24} />
            <h2 style={{ fontSize: '1.25rem', fontWeight: 600 }}>Falha de Comunicação com a API</h2>
          </div>
          <p style={{ marginTop: '0.5rem', color: 'var(--text-secondary)' }}>
            Não foi possível carregar as informações do backend. Certifique-se de que os containers Docker estão rodando (<code>docker compose up -d</code>) e o backend está exposto na porta 8000.
          </p>
          <p style={{ marginTop: '0.5rem', color: 'var(--text-muted)', fontSize: '0.85rem' }}>
            Detalhes do erro: {error}
          </p>
          <button 
            className="refresh-button" 
            style={{ marginTop: '1.25rem', width: 'fit-content' }} 
            onClick={handleRefresh}
            disabled={refreshing}
          >
            <RefreshCw size={14} className={refreshing ? 'animate-spin' : ''} />
            Tentar Novamente
          </button>
        </div>
      ) : (
        <>
          {/* Status Metrics Bar */}
          <div className="db-status-bar">
            <div className="status-card">
              <div className="icon-wrapper primary">
                <Database size={22} />
              </div>
              <div className="status-info">
                <h3>Banco de Dados</h3>
                <p>PostgreSQL 16</p>
              </div>
            </div>

            <div className="status-card">
              <div className="icon-wrapper success">
                <Layers size={22} />
              </div>
              <div className="status-info">
                <h3>Tabelas Criadas</h3>
                <p>{dbStatus?.tabelas_criadas?.length || 0} Tabelas</p>
              </div>
            </div>

            <div className="status-card">
              <div className="icon-wrapper warning">
                <ShieldAlert size={22} />
              </div>
              <div className="status-info">
                <h3>Logs Registrados</h3>
                <p>{logs.length} Eventos</p>
              </div>
            </div>

            <div className="status-card">
              <div className="icon-wrapper danger">
                <Package size={22} />
              </div>
              <div className="status-info">
                <h3>Produtos Ativos</h3>
                <p>{products.length} Cadastrados</p>
              </div>
            </div>
          </div>

          {/* Grid Panels */}
          <div className="dashboard-grid">
            {/* Products Panel */}
            <div className="panel">
              <div className="panel-header">
                <div className="panel-title">
                  <Package size={20} />
                  <h2>Catálogo de Produtos</h2>
                </div>
                <button 
                  className="refresh-button" 
                  onClick={handleRefresh}
                  disabled={refreshing}
                >
                  <RefreshCw size={14} className={refreshing ? 'animate-spin' : ''} />
                  Atualizar
                </button>
              </div>

              <div className="products-container">
                {products.length === 0 ? (
                  <div className="empty-state">Nenhum produto cadastrado no banco.</div>
                ) : (
                  products.map((product) => (
                    <div className="product-card" key={product.id}>
                      <div className="product-category">{product.categoria || 'Sem categoria'}</div>
                      <div className="product-name">{product.nome}</div>
                      <div className="product-desc">{product.descricao}</div>
                      <div className="product-footer">
                        <span className="product-price">{formatPrice(product.preco)}</span>
                        <span className={`product-stock ${product.estoque <= 15 ? 'stock-low' : ''}`}>
                          Estoque: {product.estoque}
                        </span>
                      </div>
                    </div>
                  ))
                )}
              </div>
            </div>

            {/* Audit Logs Panel */}
            <div className="panel">
              <div className="panel-header">
                <div className="panel-title">
                  <Terminal size={20} />
                  <h2>Logs de Segurança e Auditoria</h2>
                </div>
                <span className="badge badge-connected" style={{ fontSize: '0.75rem' }}>
                  Auditoria de Triggers
                </span>
              </div>

              <div className="logs-timeline">
                {logs.length === 0 ? (
                  <div className="empty-state">Nenhum log registrado ainda.</div>
                ) : (
                  logs.map((log) => {
                    const logClass = getLogLevelClass(log.evento);
                    return (
                      <div className={`log-item ${logClass}`} key={log.id}>
                        <div className="log-header">
                          <span className={`log-event ${logClass}`}>{log.evento}</span>
                          <span className="log-time">{formatDateTime(log.data_evento)}</span>
                        </div>
                        {renderLogDetails(log)}
                        <div className="log-metadata">
                          <div className="log-meta-item">
                            <User size={12} />
                            <span>{log.usuario || 'Ação do Sistema'}</span>
                          </div>
                          {log.ip_origem && (
                            <div className="log-meta-item">
                              <MapPin size={12} />
                              <span>{log.ip_origem}</span>
                            </div>
                          )}
                          {log.tabela_afetada && (
                            <div className="log-meta-item">
                              <Database size={12} />
                              <span>Tabela: {log.tabela_afetada}</span>
                            </div>
                          )}
                        </div>
                      </div>
                    );
                  })
                )}
              </div>
            </div>
          </div>
        </>
      )}

      {/* Footer Info */}
      <footer style={{ marginTop: '3rem', textAlign: 'center', color: 'var(--text-muted)', fontSize: '0.85rem' }}>
        <p>Projeto de Banco de Dados II — UFES</p>
        <p style={{ marginTop: '0.25rem' }}>Foco: Triggers de Auditoria, Restrições de Integridade e Isolamento via Docker.</p>
      </footer>
    </div>
  );
}

export default App;
