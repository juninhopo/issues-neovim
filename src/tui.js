#!/usr/bin/env node

const blessed = require('blessed');
const contrib = require('blessed-contrib');
const { Octokit } = require('octokit');
const chalk = require('chalk');

// Estado global da aplicação
const state = {
  issues: [],
  selectedIssue: null,
  selectedTab: 0,
  token: process.env.GITHUB_TOKEN || null,
  loading: false,
  error: null,
  page: 1,
  perPage: 30,
  issueState: 'open', // 'open' ou 'closed'
  searchTerm: '',
  view: 'issues', // 'issues', 'details', 'create', 'comment'
  needsAuth: true, // Adicione esta linha
  owner: 'LazyVim', // Valor padrão
  repo: 'LazyVim'   // Valor padrão
};

// Inicializa a tela
const screen = blessed.screen({
  smartCSR: true,
  title: 'GitHub Issues CLI',
  dockBorders: true,
  fullUnicode: true,
});

// Layout principal usando grid
const grid = new contrib.grid({ rows: 12, cols: 12, screen: screen });

// Componentes da interface
const header = grid.set(0, 0, 1, 12, blessed.box, {
  content: ' {bold}GitHub Issues CLI{/bold} ',
  tags: true,
  style: {
    fg: 'white',
    bg: 'blue',
  },
});

const tabs = grid.set(1, 0, 1, 12, blessed.listbar, {
  keys: true,
  mouse: true,
  style: {
    bg: 'black',
    item: {
      bg: 'black',
      fg: 'white',
      hover: {
        bg: 'blue',
      },
    },
    selected: {
      bg: 'blue',
      fg: 'white',
    },
  },
  commands: {
    'Issues Abertas': {
      keys: ['1'],
      callback: () => {
        state.issueState = 'open';
        state.selectedTab = 0;
        refreshIssues();
      },
    },
    'Issues Fechadas': {
      keys: ['2'],
      callback: () => {
        state.issueState = 'closed';
        state.selectedTab = 1;
        refreshIssues();
      },
    },
    'Buscar': {
      keys: ['3'],
      callback: promptSearch,
    },
    'Criar Issue': {
      keys: ['4'],
      callback: promptCreateIssue,
    },
    'Sair (q)': {
      keys: ['q'],
      callback: () => process.exit(0),
    },
  },
});

const issuesList = grid.set(2, 0, 8, 4, blessed.list, {
  keys: true,
  mouse: true,
  label: ' Issues ',
  border: {
    type: 'line',
  },
  style: {
    selected: {
      bg: 'blue',
      fg: 'white',
    },
    border: {
      fg: 'white',
    },
  },
  scrollbar: {
    ch: ' ',
    style: {
      bg: 'blue',
    },
  },
});

const issueDetails = grid.set(2, 4, 8, 8, blessed.box, {
  label: ' Detalhes da Issue ',
  content: 'Selecione uma issue para ver os detalhes',
  tags: true,
  border: {
    type: 'line',
  },
  style: {
    border: {
      fg: 'white',
    },
  },
  scrollable: true,
  alwaysScroll: true,
  scrollbar: {
    ch: ' ',
    style: {
      bg: 'blue',
    },
  },
});

const statusBar = grid.set(10, 0, 1, 12, blessed.text, {
  content: ' Carregando...',
  tags: true,
  style: {
    fg: 'white',
    bg: 'blue',
  },
});

const helpBar = grid.set(11, 0, 1, 12, blessed.text, {
  content: ' {bold}↑/↓{/bold}: Navegar  {bold}Enter{/bold}: Ver Detalhes  {bold}c{/bold}: Comentar  {bold}r{/bold}: Recarregar  {bold}q{/bold}: Sair',
  tags: true,
  style: {
    fg: 'white',
    bg: 'black',
  },
});

// Inicializa a API do GitHub
async function initOctokit() {
  // Para operações apenas de leitura em repositórios públicos, o token é opcional
  if (!state.token && state.needsAuth) {
    state.token = await promptGitHubToken();
  }
  
  // Se não precisar de autenticação ou já tiver token, retorna a instância do Octokit
  return new Octokit({ 
    auth: state.token || undefined
  });
}

// Prompt para o token do GitHub
function promptGitHubToken() {
  return new Promise((resolve) => {
    const prompt = blessed.prompt({
      parent: screen,
      border: 'line',
      height: 'shrink',
      width: 'half',
      top: 'center',
      left: 'center',
      label: ' Token do GitHub ',
      hidden: true,
      keys: true,
      vi: true,
    });

    prompt.input('Digite seu token de acesso pessoal do GitHub (opcional para visualização):', '', (err, value) => {
      prompt.destroy();
      screen.render();
      resolve(value);
    });

    screen.render();
  });
}

// Função para verificar se é necessária autenticação
function requiresAuth(operation) {
  // Operações de escrita sempre precisam de autenticação
  const writeOperations = ['create', 'update', 'delete', 'comment'];
  return writeOperations.includes(operation);
}

// Prompt para busca
function promptSearch() {
  const prompt = blessed.prompt({
    parent: screen,
    border: 'line',
    height: 'shrink',
    width: 'half',
    top: 'center',
    left: 'center',
    label: ' Buscar Issues ',
    keys: true,
    vi: true,
  });

  prompt.input('Digite o termo de busca:', state.searchTerm, (err, value) => {
    if (value) {
      state.searchTerm = value;
      searchIssues();
    }
    prompt.destroy();
    screen.render();
  });

  screen.render();
}

// Prompt para criar uma issue
function promptCreateIssue() {
  const form = blessed.form({
    parent: screen,
    keys: true,
    vi: true,
    left: 'center',
    top: 'center',
    width: '80%',
    height: 15,
    bg: 'black',
    border: {
      type: 'line',
    },
    label: ' Criar Nova Issue ',
  });

  blessed.text({
    parent: form,
    left: 1,
    top: 1,
    content: 'Título:',
  });

  const titleInput = blessed.textbox({
    parent: form,
    name: 'title',
    inputOnFocus: true,
    left: 1,
    top: 2,
    height: 1,
    width: '95%',
    style: {
      fg: 'white',
      bg: 'black',
      focus: {
        bg: 'blue',
      },
    },
    border: {
      type: 'line',
    },
  });

  blessed.text({
    parent: form,
    left: 1,
    top: 4,
    content: 'Descrição:',
  });

  const bodyInput = blessed.textarea({
    parent: form,
    name: 'body',
    inputOnFocus: true,
    left: 1,
    top: 5,
    height: 5,
    width: '95%',
    style: {
      fg: 'white',
      bg: 'black',
      focus: {
        bg: 'blue',
      },
    },
    border: {
      type: 'line',
    },
  });

  const submitButton = blessed.button({
    parent: form,
    name: 'submit',
    content: 'Criar',
    left: 1,
    top: 11,
    width: 10,
    height: 1,
    style: {
      bg: 'green',
      focus: {
        bg: 'blue',
      },
      hover: {
        bg: 'blue',
      },
    },
  });

  const cancelButton = blessed.button({
    parent: form,
    name: 'cancel',
    content: 'Cancelar',
    left: 15,
    top: 11,
    width: 10,
    height: 1,
    style: {
      bg: 'red',
      focus: {
        bg: 'blue',
      },
      hover: {
        bg: 'blue',
      },
    },
  });

  submitButton.on('press', () => {
    const title = titleInput.getValue();
    const body = bodyInput.getValue();
    
    if (title.trim()) {
      form.destroy();
      createIssue(title, body);
    } else {
      showMessage('O título é obrigatório!', 'error');
    }
  });

  cancelButton.on('press', () => {
    form.destroy();
    screen.render();
  });

  titleInput.focus();
  screen.render();
}

// Função para comentar em uma issue
function promptComment() {
  if (!state.selectedIssue) {
    showMessage('Selecione uma issue primeiro!', 'error');
    return;
  }

  const form = blessed.form({
    parent: screen,
    keys: true,
    vi: true,
    left: 'center',
    top: 'center',
    width: '80%',
    height: 11,
    bg: 'black',
    border: {
      type: 'line',
    },
    label: ` Comentar na Issue #${state.selectedIssue.number} `,
  });

  blessed.text({
    parent: form,
    left: 1,
    top: 1,
    content: 'Comentário:',
  });

  const commentInput = blessed.textarea({
    parent: form,
    name: 'comment',
    inputOnFocus: true,
    left: 1,
    top: 2,
    height: 5,
    width: '95%',
    style: {
      fg: 'white',
      bg: 'black',
      focus: {
        bg: 'blue',
      },
    },
    border: {
      type: 'line',
    },
  });

  const submitButton = blessed.button({
    parent: form,
    name: 'submit',
    content: 'Enviar',
    left: 1,
    top: 8,
    width: 10,
    height: 1,
    style: {
      bg: 'green',
      focus: {
        bg: 'blue',
      },
      hover: {
        bg: 'blue',
      },
    },
  });

  const cancelButton = blessed.button({
    parent: form,
    name: 'cancel',
    content: 'Cancelar',
    left: 15,
    top: 8,
    width: 10,
    height: 1,
    style: {
      bg: 'red',
      focus: {
        bg: 'blue',
      },
      hover: {
        bg: 'blue',
      },
    },
  });

  submitButton.on('press', () => {
    const comment = commentInput.getValue();
    
    if (comment.trim()) {
      form.destroy();
      createComment(comment);
    } else {
      showMessage('O comentário não pode estar vazio!', 'error');
    }
  });

  cancelButton.on('press', () => {
    form.destroy();
    screen.render();
  });

  commentInput.focus();
  screen.render();
}

// Função para mostrar mensagens
function showMessage(message, type = 'info') {
  const colors = {
    info: 'blue',
    success: 'green',
    error: 'red',
  };

  const messageBox = blessed.message({
    parent: screen,
    border: 'line',
    height: 'shrink',
    width: 'half',
    top: 'center',
    left: 'center',
    style: {
      border: {
        fg: colors[type],
      },
    },
  });

  messageBox.display(message, 3, () => {
    screen.render();
  });

  screen.render();
}

// função para atualizar o título da tela com o repositório
function updateTitle() {
  const title = `GitHub Issues: ${state.owner}/${state.repo}`;
  screen.title = title;
  header.setContent(` {bold}${title}{/bold} `);
  screen.render();
}

// Funções para interagir com a API do GitHub
async function fetchIssues() {
  try {
    state.loading = true;
    state.needsAuth = false; // Visualizar issues é operação de leitura
    updateStatus(`Carregando issues ${state.issueState === 'open' ? 'abertas' : 'fechadas'}...`);
    screen.render();

    const octokit = await initOctokit();
    
    const { data: issues } = await octokit.rest.issues.listForRepo({
      owner: state.owner,
      repo: state.repo,
      state: state.issueState,
      per_page: state.perPage,
      page: state.page,
    });

    state.issues = issues;
    updateIssuesList();
    updateStatus(`${issues.length} issues carregadas de ${state.owner}/${state.repo}`);
  } catch (error) {
    state.error = error.message;
    updateStatus(`Erro: ${error.message}`, 'error');
  } finally {
    state.loading = false;
    screen.render();
  }
}

async function searchIssues() {
  try {
    state.loading = true;
    state.needsAuth = false; // Buscar issues é operação de leitura
    updateStatus(`Buscando por "${state.searchTerm}"...`);
    screen.render();

    const octokit = await initOctokit();
    
    const { data: result } = await octokit.rest.search.issuesAndPullRequests({
      q: `repo:${state.owner}/${state.repo} ${state.searchTerm} in:title,body`,
      per_page: state.perPage,
      page: state.page,
    });

    state.issues = result.items;
    updateIssuesList();
    updateStatus(`${result.total_count} resultados encontrados para "${state.searchTerm}" em ${state.owner}/${state.repo}`);
  } catch (error) {
    state.error = error.message;
    updateStatus(`Erro: ${error.message}`, 'error');
  } finally {
    state.loading = false;
    screen.render();
  }
}

async function fetchIssueDetails(issueNumber) {
  try {
    state.loading = true;
    state.needsAuth = false; // Ver detalhes é operação de leitura
    updateStatus(`Carregando detalhes da issue #${issueNumber}...`);
    screen.render();

    const octokit = await initOctokit();
    
    const { data: issue } = await octokit.rest.issues.get({
      owner: state.owner,
      repo: state.repo,
      issue_number: issueNumber,
    });

    const { data: comments } = await octokit.rest.issues.listComments({
      owner: state.owner,
      repo: state.repo,
      issue_number: issueNumber,
      per_page: 100,
    });

    updateIssueDetails(issue, comments);
    updateStatus(`Detalhes da issue #${issueNumber} carregados de ${state.owner}/${state.repo}`);
  } catch (error) {
    state.error = error.message;
    updateStatus(`Erro: ${error.message}`, 'error');
  } finally {
    state.loading = false;
    screen.render();
  }
}

async function createIssue(title, body) {
  try {
    state.loading = true;
    state.needsAuth = true; // Criar issue é operação de escrita
    updateStatus('Criando issue...');
    screen.render();

    const octokit = await initOctokit();
    
    if (!state.token) {
      showMessage('É necessário um token do GitHub para criar issues!', 'error');
      return;
    }
    
    const { data: issue } = await octokit.rest.issues.create({
      owner: state.owner,
      repo: state.repo,
      title,
      body,
    });

    showMessage(`Issue #${issue.number} criada com sucesso em ${state.owner}/${state.repo}!`, 'success');
    refreshIssues();
  } catch (error) {
    state.error = error.message;
    updateStatus(`Erro: ${error.message}`, 'error');
  } finally {
    state.loading = false;
    screen.render();
  }
}

async function createComment(body) {
  try {
    if (!state.selectedIssue) return;
    
    state.loading = true;
    state.needsAuth = true; // Comentar é operação de escrita
    updateStatus(`Comentando na issue #${state.selectedIssue.number}...`);
    screen.render();

    const octokit = await initOctokit();
    
    if (!state.token) {
      showMessage('É necessário um token do GitHub para adicionar comentários!', 'error');
      return;
    }
    
    await octokit.rest.issues.createComment({
      owner: state.owner,
      repo: state.repo,
      issue_number: state.selectedIssue.number,
      body,
    });

    showMessage('Comentário adicionado com sucesso!', 'success');
    fetchIssueDetails(state.selectedIssue.number);
  } catch (error) {
    state.error = error.message;
    updateStatus(`Erro: ${error.message}`, 'error');
  } finally {
    state.loading = false;
    screen.render();
  }
}

// Funções para atualizar a interface
function updateIssuesList() {
  issuesList.setItems(
    state.issues.map((issue) => {
      let prefix = '#' + issue.number;
      if (issue.state === 'open') {
        prefix = '{green-fg}' + prefix + '{/green-fg}';
      } else {
        prefix = '{red-fg}' + prefix + '{/red-fg}';
      }
      return `${prefix} ${issue.title.substring(0, 40)}${issue.title.length > 40 ? '...' : ''}`;
    })
  );

  if (state.issues.length > 0) {
    issuesList.select(0);
    state.selectedIssue = state.issues[0];
  }

  screen.render();
}

function updateIssueDetails(issue, comments = []) {
  state.selectedIssue = issue;

  const stateColor = issue.state === 'open' ? '{green-fg}Aberta{/green-fg}' : '{red-fg}Fechada{/red-fg}';
  
  let content = '';
  content += `{bold}#${issue.number}: ${issue.title}{/bold}\n\n`;
  content += `{bold}Estado:{/bold} ${stateColor}\n`;
  content += `{bold}Criada por:{/bold} ${issue.user.login}\n`;
  content += `{bold}Criada em:{/bold} ${new Date(issue.created_at).toLocaleString()}\n`;
  
  if (issue.labels.length > 0) {
    content += `{bold}Labels:{/bold} ${issue.labels.map((l) => l.name).join(', ')}\n`;
  }
  
  content += `\n{bold}Descrição:{/bold}\n${issue.body || 'Sem descrição'}\n\n`;
  
  if (comments.length > 0) {
    content += `{bold}Comentários (${comments.length}):{/bold}\n\n`;
    
    comments.forEach((comment) => {
      content += `{bold}${comment.user.login}{/bold} em ${new Date(comment.created_at).toLocaleString()}\n`;
      content += `${comment.body}\n\n`;
    });
  } else {
    content += '{bold}Comentários:{/bold} Nenhum comentário ainda\n';
  }
  
  issueDetails.setContent(content);
  screen.render();
}

function updateStatus(message, type = 'info') {
  const colors = {
    info: '{white-fg}{blue-bg}',
    success: '{white-fg}{green-bg}',
    error: '{white-fg}{red-bg}',
  };

  statusBar.setContent(`${colors[type]} ${message} {/}`);
  screen.render();
}

function refreshIssues() {
  state.selectedIssue = null;
  issueDetails.setContent('Carregando...');
  fetchIssues();
}

// Eventos e atalhos de teclado
issuesList.on('select', (item, index) => {
  const issue = state.issues[index];
  if (issue) {
    fetchIssueDetails(issue.number);
  }
});

screen.key(['escape', 'q', 'C-c'], () => {
  return process.exit(0);
});

screen.key('r', () => {
  refreshIssues();
});

screen.key('c', () => {
  promptComment();
});

// Inicializar
screen.title = 'LazyVim Issues CLI';
screen.key(['tab'], (ch, key) => {
  if (screen.focused.parent === issuesList.parent) {
    issueDetails.focus();
  } else {
    issuesList.focus();
  }
});

issuesList.focus();
fetchIssues();

// Habilitar o mouse
screen.enableMouse();

module.exports = {
  start: (owner, repo) => {
    if (owner && repo) {
      state.owner = owner;
      state.repo = repo;
      updateTitle();
    }
    screen.render();
  },
};

// Se este arquivo for executado diretamente
if (require.main === module) {
  screen.render();
} 