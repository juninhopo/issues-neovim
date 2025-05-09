#!/usr/bin/env node

const { program } = require('commander');
const { Octokit } = require('octokit');
const chalk = require('chalk');
const inquirer = require('inquirer');
const ora = require('ora');
const simpleGit = require('simple-git');
const path = require('path');
const fs = require('fs');

// Estado do repositório
let OWNER = 'LazyVim';
let REPO = 'LazyVim';
let repoDetected = false;

// Função para detectar o repositório atual
async function detectRepository() {
  try {
    const git = simpleGit(process.cwd());
    
    // Verificar se estamos em um repositório git
    const isRepo = await git.checkIsRepo();
    if (!isRepo) {
      console.log(chalk.yellow('Aviso: Não estamos em um repositório Git. Usando o repositório padrão (LazyVim/LazyVim).'));
      return false;
    }
    
    // Obter a URL remota
    const remotes = await git.getRemotes(true);
    if (!remotes || remotes.length === 0) {
      console.log(chalk.yellow('Aviso: Não há remotes configurados. Usando o repositório padrão (LazyVim/LazyVim).'));
      return false;
    }
    
    // Procurar pelo remote origin ou o primeiro disponível
    const remote = remotes.find(r => r.name === 'origin') || remotes[0];
    const url = remote.refs.fetch;
    
    // Extrair owner e repo da URL do GitHub
    // Suporta formatos https://github.com/owner/repo.git e git@github.com:owner/repo.git
    let match;
    if (url.includes('github.com')) {
      if (url.startsWith('https')) {
        match = url.match(/github\.com\/([^\/]+)\/([^\/\.]+)(\.git)?$/);
      } else {
        match = url.match(/github\.com:([^\/]+)\/([^\/\.]+)(\.git)?$/);
      }
      
      if (match && match.length >= 3) {
        OWNER = match[1];
        REPO = match[2];
        console.log(chalk.green(`Repositório detectado: ${OWNER}/${REPO}`));
        return true;
      }
    }
    
    console.log(chalk.yellow(`Aviso: Não foi possível extrair informações do GitHub da URL: ${url}`));
    console.log(chalk.yellow('Usando o repositório padrão (LazyVim/LazyVim).'));
    return false;
  } catch (error) {
    console.log(chalk.yellow(`Aviso: Erro ao detectar repositório: ${error.message}`));
    console.log(chalk.yellow('Usando o repositório padrão (LazyVim/LazyVim).'));
    return false;
  }
}

// Configuração da versão e descrição do CLI
program
  .name('issue-lazyvim')
  .description('CLI para gerenciar issues do GitHub')
  .version('1.0.0');

// Função para inicializar a API do GitHub
async function initOctokit(requireAuth = false) {
  // Verifica se o token existe
  let token = process.env.GITHUB_TOKEN;
  
  if (!token && requireAuth) {
    const response = await inquirer.prompt([
      {
        type: 'password',
        name: 'token',
        message: 'Digite seu token de acesso pessoal do GitHub:',
        validate: input => input.length > 0 ? true : 'Token é obrigatório para esta operação'
      }
    ]);
    token = response.token;
    console.log(chalk.yellow('Dica: Para evitar digitar o token toda vez, configure a variável GITHUB_TOKEN no seu ambiente.'));
  } else if (!token && !requireAuth) {
    console.log(chalk.blue('Acessando GitHub sem autenticação. Algumas operações podem ser limitadas.'));
  }
  
  return new Octokit({ auth: token || undefined });
}

// Comando para iniciar a interface TUI
program
  .command('tui')
  .description('Iniciar a interface TUI (Terminal User Interface)')
  .action(async () => {
    // Detectar repositório antes de iniciar a TUI
    repoDetected = await detectRepository();
    // Carrega e inicia o módulo TUI
    require('./tui').start(OWNER, REPO);
  });

// Comando para listar issues
program
  .command('listar')
  .description('Listar issues do repositório')
  .option('-a, --abertas', 'Mostrar apenas issues abertas', true)
  .option('-f, --fechadas', 'Mostrar apenas issues fechadas')
  .option('-l, --limite <número>', 'Número máximo de issues para exibir', '10')
  .action(async (options) => {
    try {
      // Detectar repositório
      repoDetected = await detectRepository();
      
      const spinner = ora('Buscando issues...').start();
      
      // Listar issues não requer autenticação para repositórios públicos
      const octokit = await initOctokit(false);
      const state = options.fechadas ? 'closed' : 'open';
      
      const { data: issues } = await octokit.rest.issues.listForRepo({
        owner: OWNER,
        repo: REPO,
        state,
        per_page: parseInt(options.limite)
      });
      
      spinner.stop();
      
      if (issues.length === 0) {
        console.log(chalk.yellow(`Nenhuma issue ${state === 'open' ? 'aberta' : 'fechada'} encontrada em ${OWNER}/${REPO}.`));
        return;
      }
      
      console.log(chalk.bold(`\nIssues ${state === 'open' ? 'abertas' : 'fechadas'} de ${OWNER}/${REPO}:\n`));
      
      issues.forEach(issue => {
        console.log(
          `${chalk.green('#' + issue.number)} ${chalk.white(issue.title)}`
        );
        console.log(`  ${chalk.blue(issue.html_url)}`);
        console.log(`  ${chalk.gray('Criado em: ' + new Date(issue.created_at).toLocaleDateString())}`);
        console.log();
      });
    } catch (error) {
      console.error(chalk.red('Erro ao buscar issues:'), error.message);
      process.exit(1);
    }
  });

// Comando para ver detalhes de uma issue
program
  .command('ver <número>')
  .description('Ver detalhes de uma issue específica')
  .action(async (número) => {
    try {
      // Detectar repositório
      repoDetected = await detectRepository();
      
      const spinner = ora('Buscando detalhes da issue...').start();
      
      // Ver detalhes não requer autenticação para repositórios públicos
      const octokit = await initOctokit(false);
      
      const { data: issue } = await octokit.rest.issues.get({
        owner: OWNER,
        repo: REPO,
        issue_number: parseInt(número)
      });
      
      spinner.stop();
      
      console.log(chalk.bold.green(`\n#${issue.number}: ${issue.title}\n`));
      console.log(`${chalk.blue('Repositório:')} ${OWNER}/${REPO}`);
      console.log(`${chalk.blue('URL:')} ${issue.html_url}`);
      console.log(`${chalk.blue('Estado:')} ${issue.state === 'open' ? chalk.green('Aberta') : chalk.red('Fechada')}`);
      console.log(`${chalk.blue('Criado em:')} ${new Date(issue.created_at).toLocaleString()}`);
      console.log(`${chalk.blue('Criado por:')} ${issue.user.login}`);
      
      if (issue.labels.length > 0) {
        console.log(`${chalk.blue('Labels:')} ${issue.labels.map(label => label.name).join(', ')}`);
      }
      
      console.log(`\n${chalk.blue('Descrição:')}\n${issue.body || 'Sem descrição'}\n`);
      
    } catch (error) {
      console.error(chalk.red('Erro ao buscar detalhes da issue:'), error.message);
      process.exit(1);
    }
  });

// Comando para criar uma nova issue
program
  .command('criar')
  .description('Criar uma nova issue no repositório')
  .action(async () => {
    try {
      // Detectar repositório
      repoDetected = await detectRepository();
      
      // Criar issues requer autenticação
      const octokit = await initOctokit(true);
      
      const answers = await inquirer.prompt([
        {
          type: 'input',
          name: 'titulo',
          message: 'Título da issue:',
          validate: input => input.length > 0 ? true : 'Título é obrigatório'
        },
        {
          type: 'editor',
          name: 'descricao',
          message: 'Descrição da issue (um editor será aberto):',
        },
        {
          type: 'confirm',
          name: 'confirmar',
          message: `Confirmar criação da issue em ${OWNER}/${REPO}?`,
          default: true
        }
      ]);
      
      if (!answers.confirmar) {
        console.log(chalk.yellow('Criação da issue cancelada.'));
        return;
      }
      
      const spinner = ora('Criando issue...').start();
      
      const { data: novaIssue } = await octokit.rest.issues.create({
        owner: OWNER,
        repo: REPO,
        title: answers.titulo,
        body: answers.descricao || ''
      });
      
      spinner.stop();
      
      console.log(chalk.green(`\nIssue #${novaIssue.number} criada com sucesso em ${OWNER}/${REPO}!`));
      console.log(`URL: ${chalk.blue(novaIssue.html_url)}\n`);
      
    } catch (error) {
      console.error(chalk.red('Erro ao criar issue:'), error.message);
      process.exit(1);
    }
  });

// Comando para comentar em uma issue
program
  .command('comentar <número>')
  .description('Adicionar um comentário a uma issue')
  .action(async (número) => {
    try {
      // Detectar repositório
      repoDetected = await detectRepository();
      
      // Comentar requer autenticação
      const octokit = await initOctokit(true);
      
      const answers = await inquirer.prompt([
        {
          type: 'editor',
          name: 'comentario',
          message: 'Digite seu comentário (um editor será aberto):',
          validate: input => input.length > 0 ? true : 'O comentário não pode estar vazio'
        },
        {
          type: 'confirm',
          name: 'confirmar',
          message: `Confirmar envio do comentário na issue #${número} de ${OWNER}/${REPO}?`,
          default: true
        }
      ]);
      
      if (!answers.confirmar) {
        console.log(chalk.yellow('Envio do comentário cancelado.'));
        return;
      }
      
      const spinner = ora('Enviando comentário...').start();
      
      await octokit.rest.issues.createComment({
        owner: OWNER,
        repo: REPO,
        issue_number: parseInt(número),
        body: answers.comentario
      });
      
      spinner.stop();
      
      console.log(chalk.green(`\nComentário adicionado com sucesso na issue #${número} de ${OWNER}/${REPO}!`));
      
    } catch (error) {
      console.error(chalk.red('Erro ao adicionar comentário:'), error.message);
      process.exit(1);
    }
  });

// Comando para buscar issues
program
  .command('buscar <termo>')
  .description('Buscar issues por termo')
  .action(async (termo) => {
    try {
      // Detectar repositório
      repoDetected = await detectRepository();
      
      const spinner = ora('Buscando issues...').start();
      
      // Buscar issues não requer autenticação para repositórios públicos
      const octokit = await initOctokit(false);
      
      const { data: resultados } = await octokit.rest.search.issuesAndPullRequests({
        q: `repo:${OWNER}/${REPO} ${termo} in:title,body`,
      });
      
      spinner.stop();
      
      if (resultados.items.length === 0) {
        console.log(chalk.yellow(`Nenhuma issue encontrada com o termo "${termo}" em ${OWNER}/${REPO}.`));
        return;
      }
      
      console.log(chalk.bold(`\nResultados da busca por "${termo}" em ${OWNER}/${REPO} (${resultados.total_count} encontrados):\n`));
      
      resultados.items.slice(0, 10).forEach(issue => {
        console.log(
          `${chalk.green('#' + issue.number)} ${chalk.white(issue.title)}`
        );
        console.log(`  ${chalk.blue(issue.html_url)}`);
        console.log(`  ${chalk.gray('Estado: ' + (issue.state === 'open' ? 'Aberto' : 'Fechado'))}`);
        console.log();
      });
      
      if (resultados.total_count > 10) {
        console.log(chalk.yellow(`...e mais ${resultados.total_count - 10} resultados não exibidos.`));
      }
      
    } catch (error) {
      console.error(chalk.red('Erro ao buscar issues:'), error.message);
      process.exit(1);
    }
  });

// Analisar argumentos da linha de comando
program.parse(process.argv);

// Se nenhum comando for fornecido, iniciar a TUI por padrão
if (!process.argv.slice(2).length) {
  // Detectar repositório antes de iniciar a TUI
  detectRepository().then((detected) => {
    repoDetected = detected;
    require('./tui').start(OWNER, REPO);
  });
} 