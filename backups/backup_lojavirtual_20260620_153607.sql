--
-- PostgreSQL database dump
--

\restrict lW311UfQdBggxDhQUkRlqjpf9pP1eqPRTzd7kxlcpdq3LktgG3SKbBV5hWNzlKB

-- Dumped from database version 16.14
-- Dumped by pg_dump version 16.14

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: audit_produtos_trigger(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.audit_produtos_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF (TG_OP = 'UPDATE') THEN
        INSERT INTO logs_auditoria (evento, tabela_afetada, dados_antigos, dados_novos)
        VALUES ('UPDATE', 'produtos', to_jsonb(OLD), to_jsonb(NEW));
        RETURN NEW;
    ELSIF (TG_OP = 'DELETE') THEN
        INSERT INTO logs_auditoria (evento, tabela_afetada, dados_antigos, dados_novos)
        VALUES ('DELETE', 'produtos', to_jsonb(OLD), NULL);
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$;


ALTER FUNCTION public.audit_produtos_trigger() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: categorias; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.categorias (
    id integer NOT NULL,
    nome character varying(100) NOT NULL,
    descricao text,
    data_criacao timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.categorias OWNER TO postgres;

--
-- Name: categorias_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.categorias_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.categorias_id_seq OWNER TO postgres;

--
-- Name: categorias_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.categorias_id_seq OWNED BY public.categorias.id;


--
-- Name: itens_pedido; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.itens_pedido (
    id integer NOT NULL,
    pedido_id integer NOT NULL,
    produto_id integer NOT NULL,
    quantidade integer NOT NULL,
    preco_unitario numeric(10,2) NOT NULL,
    CONSTRAINT chk_preco_unitario CHECK ((preco_unitario >= (0)::numeric)),
    CONSTRAINT chk_quantidade CHECK ((quantidade > 0))
);


ALTER TABLE public.itens_pedido OWNER TO postgres;

--
-- Name: itens_pedido_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.itens_pedido_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.itens_pedido_id_seq OWNER TO postgres;

--
-- Name: itens_pedido_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.itens_pedido_id_seq OWNED BY public.itens_pedido.id;


--
-- Name: logs_auditoria; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.logs_auditoria (
    id integer NOT NULL,
    usuario_id integer,
    evento character varying(100) NOT NULL,
    tabela_afetada character varying(50) NOT NULL,
    dados_antigos jsonb,
    dados_novos jsonb,
    detalhes text,
    ip_origem character varying(45),
    data_evento timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.logs_auditoria OWNER TO postgres;

--
-- Name: logs_auditoria_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.logs_auditoria_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.logs_auditoria_id_seq OWNER TO postgres;

--
-- Name: logs_auditoria_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.logs_auditoria_id_seq OWNED BY public.logs_auditoria.id;


--
-- Name: pedidos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pedidos (
    id integer NOT NULL,
    usuario_id integer NOT NULL,
    data_pedido timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    status character varying(50) DEFAULT 'pendente'::character varying NOT NULL,
    total numeric(10,2) DEFAULT 0.00 NOT NULL,
    CONSTRAINT chk_status CHECK (((status)::text = ANY ((ARRAY['pendente'::character varying, 'pago'::character varying, 'enviado'::character varying, 'entregue'::character varying, 'cancelado'::character varying])::text[]))),
    CONSTRAINT chk_total CHECK ((total >= (0)::numeric))
);


ALTER TABLE public.pedidos OWNER TO postgres;

--
-- Name: pedidos_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pedidos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.pedidos_id_seq OWNER TO postgres;

--
-- Name: pedidos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pedidos_id_seq OWNED BY public.pedidos.id;


--
-- Name: produtos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.produtos (
    id integer NOT NULL,
    categoria_id integer,
    nome character varying(150) NOT NULL,
    descricao text,
    preco numeric(10,2) NOT NULL,
    estoque integer NOT NULL,
    data_cadastro timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT chk_estoque CHECK ((estoque >= 0)),
    CONSTRAINT chk_preco CHECK ((preco > (0)::numeric))
);


ALTER TABLE public.produtos OWNER TO postgres;

--
-- Name: produtos_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.produtos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.produtos_id_seq OWNER TO postgres;

--
-- Name: produtos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.produtos_id_seq OWNED BY public.produtos.id;


--
-- Name: usuarios; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.usuarios (
    id integer NOT NULL,
    nome character varying(150) NOT NULL,
    email character varying(150) NOT NULL,
    senha_hash character varying(255) NOT NULL,
    funcao character varying(50) DEFAULT 'cliente'::character varying NOT NULL,
    ativo boolean DEFAULT true NOT NULL,
    data_criacao timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT chk_funcao CHECK (((funcao)::text = ANY ((ARRAY['cliente'::character varying, 'administrador'::character varying, 'suporte'::character varying])::text[])))
);


ALTER TABLE public.usuarios OWNER TO postgres;

--
-- Name: usuarios_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.usuarios_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.usuarios_id_seq OWNER TO postgres;

--
-- Name: usuarios_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.usuarios_id_seq OWNED BY public.usuarios.id;


--
-- Name: categorias id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categorias ALTER COLUMN id SET DEFAULT nextval('public.categorias_id_seq'::regclass);


--
-- Name: itens_pedido id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.itens_pedido ALTER COLUMN id SET DEFAULT nextval('public.itens_pedido_id_seq'::regclass);


--
-- Name: logs_auditoria id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.logs_auditoria ALTER COLUMN id SET DEFAULT nextval('public.logs_auditoria_id_seq'::regclass);


--
-- Name: pedidos id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pedidos ALTER COLUMN id SET DEFAULT nextval('public.pedidos_id_seq'::regclass);


--
-- Name: produtos id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.produtos ALTER COLUMN id SET DEFAULT nextval('public.produtos_id_seq'::regclass);


--
-- Name: usuarios id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuarios ALTER COLUMN id SET DEFAULT nextval('public.usuarios_id_seq'::regclass);


--
-- Data for Name: categorias; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.categorias (id, nome, descricao, data_criacao) FROM stdin;
1	Eletrônicos	Dispositivos eletrônicos, smartphones, computadores e acessórios.	2026-06-20 18:35:38.05258
2	Vestuário	Roupas masculinas, femininas e calçados.	2026-06-20 18:35:38.05258
3	Livros	Livros físicos e e-books de diversas áreas do conhecimento.	2026-06-20 18:35:38.05258
4	Casa e Decoração	Móveis, luminárias, itens de decoração e utilidades domésticas.	2026-06-20 18:35:38.05258
5	Esportes	Artigos esportivos, vestuário fitness e equipamentos.	2026-06-20 18:35:38.05258
\.


--
-- Data for Name: itens_pedido; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.itens_pedido (id, pedido_id, produto_id, quantidade, preco_unitario) FROM stdin;
1	1	1	1	4299.00
2	1	3	1	249.90
3	2	6	1	89.90
4	2	7	1	120.00
5	3	4	2	49.90
6	3	5	1	139.90
\.


--
-- Data for Name: logs_auditoria; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.logs_auditoria (id, usuario_id, evento, tabela_afetada, dados_antigos, dados_novos, detalhes, ip_origem, data_evento) FROM stdin;
1	1	SISTEMA_INICIALIZADO	sistema	\N	\N	Banco de dados populado e sistema de e-commerce pronto.	127.0.0.1	2026-06-20 18:35:38.088465
2	1	LOGIN_SUCESSO	usuarios	\N	\N	Administrador Carlos realizou login no painel administrativo.	192.168.1.10	2026-06-20 18:35:38.088465
3	3	LOGIN_SUCESSO	usuarios	\N	\N	Cliente Bruno realizou login.	192.168.1.15	2026-06-20 18:35:38.088465
4	5	LOGIN_BLOQUEADO	usuarios	\N	\N	Tentativa de login falhou. Usuário Marcos Souza está inativo.	192.168.1.20	2026-06-20 18:35:38.088465
5	\N	UPDATE	produtos	{"id": 1, "nome": "Smartphone Galaxy S23", "preco": 4299.00, "estoque": 45, "descricao": "Smartphone Samsung Galaxy S23 256GB 5G Tela 6.1.", "categoria_id": 1, "data_cadastro": "2026-06-20T18:35:38.058388"}	{"id": 1, "nome": "Smartphone Galaxy S23", "preco": 4199.00, "estoque": 40, "descricao": "Smartphone Samsung Galaxy S23 256GB 5G Tela 6.1.", "categoria_id": 1, "data_cadastro": "2026-06-20T18:35:38.058388"}	\N	\N	2026-06-20 18:35:38.094203
6	\N	UPDATE	produtos	{"id": 2, "nome": "Notebook Dell Inspiron", "preco": 3799.00, "estoque": 15, "descricao": "Notebook Dell Inspiron 15 Intel Core i5 8GB 512GB SSD.", "categoria_id": 1, "data_cadastro": "2026-06-20T18:35:38.058388"}	{"id": 2, "nome": "Notebook Dell Inspiron", "preco": 3699.00, "estoque": 10, "descricao": "Notebook Dell Inspiron 15 Intel Core i5 8GB 512GB SSD.", "categoria_id": 1, "data_cadastro": "2026-06-20T18:35:38.058388"}	\N	\N	2026-06-20 18:35:38.098741
\.


--
-- Data for Name: pedidos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.pedidos (id, usuario_id, data_pedido, status, total) FROM stdin;
1	3	2026-06-20 18:35:38.070255	pago	4548.90
2	4	2026-06-20 18:35:38.070255	pendente	209.80
3	3	2026-06-20 18:35:38.070255	enviado	239.70
\.


--
-- Data for Name: produtos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.produtos (id, categoria_id, nome, descricao, preco, estoque, data_cadastro) FROM stdin;
3	1	Fone de Ouvido Bluetooth JBL	Fone de Ouvido JBL Tune 510BT Bluetooth Preto.	249.90	80	2026-06-20 18:35:38.058388
4	2	Camiseta Básica Algodão	Camiseta básica masculina 100% algodão cor preta.	49.90	150	2026-06-20 18:35:38.058388
5	2	Calça Jeans Premium	Calça jeans masculina modelagem slim cor azul escuro.	139.90	90	2026-06-20 18:35:38.058388
6	3	Banco de Dados Prático	Livro sobre modelagem, SQL e otimização de bancos de dados relacionais.	89.90	40	2026-06-20 18:35:38.058388
7	3	O Programador Pragmático	Livro clássico sobre desenvolvimento profissional de software.	120.00	25	2026-06-20 18:35:38.058388
8	4	Luminária de Mesa LED	Luminária articulada com regulagem de brilho e temperatura de cor.	79.90	35	2026-06-20 18:35:38.058388
9	5	Bola de Futebol de Campo	Bola oficial de futebol de campo costurada à mão.	99.90	60	2026-06-20 18:35:38.058388
1	1	Smartphone Galaxy S23	Smartphone Samsung Galaxy S23 256GB 5G Tela 6.1.	4199.00	40	2026-06-20 18:35:38.058388
2	1	Notebook Dell Inspiron	Notebook Dell Inspiron 15 Intel Core i5 8GB 512GB SSD.	3699.00	10	2026-06-20 18:35:38.058388
\.


--
-- Data for Name: usuarios; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.usuarios (id, nome, email, senha_hash, funcao, ativo, data_criacao) FROM stdin;
1	Carlos Administrador	admin@lojavirtual.com	$2b$12$Kj64YkQZpP/Y2n0l3N2YkO1RmWdD3p1ZtZ9B2P4cWqRz5S8t2vXPy	administrador	t	2026-06-20 18:35:38.066637
2	Ana Suporte	suporte@lojavirtual.com	$2b$12$R.9M3r9E3e9G3g9U3u9E3e9G3g9U3u9E3e9G3g9U3u9E3e9G3g9U3	suporte	t	2026-06-20 18:35:38.066637
3	Bruno Cliente	bruno@cliente.com	$2b$12$B.1L2i3M4e5T6a7C8o9N0o1P2q3R4s5T6u7V8w9X0y1Z2a3b4c5d6	cliente	t	2026-06-20 18:35:38.066637
4	Julia Costa	julia@cliente.com	$2b$12$J.uLiaCoSta1234567890abcdefghijklmnopqrstuvwxyz123456	cliente	t	2026-06-20 18:35:38.066637
5	Marcos Souza	marcos@cliente.com	$2b$12$M.arcosSouza1234567890abcdefghijklmnopqrstuvwxyz12345	cliente	f	2026-06-20 18:35:38.066637
\.


--
-- Name: categorias_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.categorias_id_seq', 5, true);


--
-- Name: itens_pedido_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.itens_pedido_id_seq', 6, true);


--
-- Name: logs_auditoria_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.logs_auditoria_id_seq', 6, true);


--
-- Name: pedidos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.pedidos_id_seq', 3, true);


--
-- Name: produtos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.produtos_id_seq', 9, true);


--
-- Name: usuarios_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.usuarios_id_seq', 5, true);


--
-- Name: categorias categorias_nome_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categorias
    ADD CONSTRAINT categorias_nome_key UNIQUE (nome);


--
-- Name: categorias categorias_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categorias
    ADD CONSTRAINT categorias_pkey PRIMARY KEY (id);


--
-- Name: itens_pedido itens_pedido_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.itens_pedido
    ADD CONSTRAINT itens_pedido_pkey PRIMARY KEY (id);


--
-- Name: logs_auditoria logs_auditoria_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.logs_auditoria
    ADD CONSTRAINT logs_auditoria_pkey PRIMARY KEY (id);


--
-- Name: pedidos pedidos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pedidos
    ADD CONSTRAINT pedidos_pkey PRIMARY KEY (id);


--
-- Name: produtos produtos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.produtos
    ADD CONSTRAINT produtos_pkey PRIMARY KEY (id);


--
-- Name: itens_pedido uq_pedido_produto; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.itens_pedido
    ADD CONSTRAINT uq_pedido_produto UNIQUE (pedido_id, produto_id);


--
-- Name: usuarios usuarios_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_email_key UNIQUE (email);


--
-- Name: usuarios usuarios_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_pkey PRIMARY KEY (id);


--
-- Name: idx_itens_pedido_pedido; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_itens_pedido_pedido ON public.itens_pedido USING btree (pedido_id);


--
-- Name: idx_logs_evento; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_logs_evento ON public.logs_auditoria USING btree (evento);


--
-- Name: idx_pedidos_usuario; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_pedidos_usuario ON public.pedidos USING btree (usuario_id);


--
-- Name: idx_produtos_categoria; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_produtos_categoria ON public.produtos USING btree (categoria_id);


--
-- Name: produtos trg_audit_produtos; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_audit_produtos AFTER DELETE OR UPDATE ON public.produtos FOR EACH ROW EXECUTE FUNCTION public.audit_produtos_trigger();


--
-- Name: produtos fk_categoria; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.produtos
    ADD CONSTRAINT fk_categoria FOREIGN KEY (categoria_id) REFERENCES public.categorias(id) ON DELETE SET NULL;


--
-- Name: itens_pedido fk_pedido; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.itens_pedido
    ADD CONSTRAINT fk_pedido FOREIGN KEY (pedido_id) REFERENCES public.pedidos(id) ON DELETE CASCADE;


--
-- Name: itens_pedido fk_produto; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.itens_pedido
    ADD CONSTRAINT fk_produto FOREIGN KEY (produto_id) REFERENCES public.produtos(id) ON DELETE RESTRICT;


--
-- Name: pedidos fk_usuario; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pedidos
    ADD CONSTRAINT fk_usuario FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id) ON DELETE CASCADE;


--
-- Name: logs_auditoria fk_usuario_log; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.logs_auditoria
    ADD CONSTRAINT fk_usuario_log FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id) ON DELETE SET NULL;


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: pg_database_owner
--

GRANT USAGE ON SCHEMA public TO loja_app;


--
-- Name: TABLE categorias; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.categorias TO loja_app;


--
-- Name: SEQUENCE categorias_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.categorias_id_seq TO loja_app;


--
-- Name: TABLE itens_pedido; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.itens_pedido TO loja_app;


--
-- Name: SEQUENCE itens_pedido_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.itens_pedido_id_seq TO loja_app;


--
-- Name: TABLE logs_auditoria; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.logs_auditoria TO loja_app;


--
-- Name: SEQUENCE logs_auditoria_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.logs_auditoria_id_seq TO loja_app;


--
-- Name: TABLE pedidos; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.pedidos TO loja_app;


--
-- Name: SEQUENCE pedidos_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.pedidos_id_seq TO loja_app;


--
-- Name: TABLE produtos; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.produtos TO loja_app;


--
-- Name: SEQUENCE produtos_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.produtos_id_seq TO loja_app;


--
-- Name: TABLE usuarios; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.usuarios TO loja_app;


--
-- Name: SEQUENCE usuarios_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.usuarios_id_seq TO loja_app;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT SELECT,USAGE ON SEQUENCES TO loja_app;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT SELECT,INSERT,DELETE,UPDATE ON TABLES TO loja_app;


--
-- PostgreSQL database dump complete
--

\unrestrict lW311UfQdBggxDhQUkRlqjpf9pP1eqPRTzd7kxlcpdq3LktgG3SKbBV5hWNzlKB

