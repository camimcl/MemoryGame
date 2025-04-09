import java.util.ArrayList;
import java.util.Collections;

// ESTADOS DO JOGO
final int MENU = 0, PLAYING = 1, LEVEL_COMPLETE = 2, GAME_OVER = 3, GAME_COMPLETE = 4, PAUSED = 5;
int gameState = MENU;

// MODOS DE JOGO
final int MODE_PROGRESSIVO = 0, MODE_INDIVIDUAL = 1;
int gameMode = MODE_PROGRESSIVO;

// CONFIGURAÇÕES DOS NÍVEIS
final int[][] LEVELS = { {2, 2}, {3, 4}, {4, 4} };
final String[] LEVEL_NAMES = {"Iniciante (2x2)", "Treinador (3x4)", "Mestre (4x5)"};
final int[] MAX_ATTEMPTS = { 3, 10, 15 };
final int[] LEVEL_TIME_LIMITS = { 15000, 30000, 75000 };

final color BG_COLOR = #F0F0F0;
final color CARD_COLOR = #2C3E50;
final color MATCHED_COLOR = #2ECC71;
final color REVEALED_COLOR = #E74C3C;

// ESTADO DO JOGO DA MEMÓRIA
ArrayList<Card> cards = new ArrayList<>();
Card firstCard, secondCard;

PImage cardBackRounded;

Theme pokemonTheme;
PImage cardBackImg;
PImage levelbackgroundImg;
PImage backgroundImg;
PImage backgroundImg2;

boolean lockInput = false;
int currentLevel = 0;
int score = 0;
int levelStartTime;
int levelEndTime = -1;
int revealStartTime;
int attempts = 0;
boolean levelBonusApplied = false;
int pauseStartTime = 0;
int totalPausedTime = 0;

// INFORMAÇÕES DO JOGADOR
String playerName = "";
boolean nameEntered = false;

// RANKING DOS JOGADORES (SOMENTE NA SESSÃO)
class RankingEntry {
  String name;
  int score;

  RankingEntry(String name, int score) {
    this.name = name;
    this.score = score;
  }
}
ArrayList<RankingEntry> ranking = new ArrayList<RankingEntry>();

// CONFIGURAÇÕES VISUAIS
final int CARD_MARGIN = 10;
final int CARD_ROUNDING = 12;

// ÍCONES PARA A INTERFACE
PImage timeIcon, attemptsIcon, scoreIcon;

HashMap<String, Theme> themes = new HashMap<String, Theme>();
String currentThemeName = "Pokemon";
boolean selectingTheme = false;

void settings() {
  size(1000, 600);
}

void setup() {
  timeIcon = loadImage("timeIcon.png");
  attemptsIcon = loadImage("attemptsIcon.png");
  scoreIcon = loadImage("scoreIcon.png");

  String[] pokePaths = {
    "themes/pokemon/zoroark.png",
    "themes/pokemon/charmeleon.png",
    "themes/pokemon/clefable.png",
    "themes/pokemon/pikachu.png",
    "themes/pokemon/haunter.png",
    "themes/pokemon/persian.png",
    "themes/pokemon/vulpix.png",
    "themes/pokemon/empoleon.png",
    "themes/pokemon/snorlax.png",
    "themes/pokemon/gengar.png"
  };
  themes.put("Pokemon", new Theme(
    "Pokemon",
    pokePaths,
    "themes/pokemon/cardback.jpg",
    "themes/pokemon/background.png",
    "themes/pokemon/background22.jpg",
    "themes/pokemon/levelbackground.jpg"
  ));

  String[] animePaths = {
    "themes/hxh/gon.png",
    "themes/hxh/killua.png",
    "themes/hxh/hisoka.png",
    "themes/hxh/shizuku.png",
    "themes/hxh/feitan.png",
    "themes/hxh/chrollo.png",
    "themes/hxh/kurapika.png",
    "themes/hxh/pitou.png",
    "themes/hxh/netero.png",
    "themes/hxh/leorio.png"
  };
  themes.put("HXH", new Theme(
    "HXH",
    animePaths,
    "themes/hxh/cardback.jpg",
    "themes/hxh/background3.jpg",
    "themes/hxh/background222.jpg",
    "themes/hxh/levelbackground.png"
  ));

  rectMode(CORNER);
  textFont(createFont("Arial", 20));
  surface.setTitle("Jogo da Memória - Menu");
  applyTheme("Pokemon");
  loadAssets();
}

void applyTheme(String name) {
  Theme t = themes.get(name);
  if (t != null) {
    currentThemeName = name;
    backgroundImg = t.menuBackground;
    cardBackImg = t.cardBack;
    levelbackgroundImg = t.levelCompleteBackground;
    backgroundImg2 = t.playingBackground;
    t.menuBackground.resize(width, height);
    t.playingBackground.resize(width, height);
    t.levelCompleteBackground.resize(width, height);
  }
  cardBackRounded = createRoundedImage(cardBackImg, 10);
}

void loadAssets() {
  Theme currentTheme = themes.get(currentThemeName);
  if (currentTheme == null) return;

  backgroundImg = currentTheme.menuBackground;
  backgroundImg.resize(width, height);

  levelbackgroundImg = currentTheme.levelCompleteBackground;
  levelbackgroundImg.resize(width, height);

  backgroundImg2 = currentTheme.playingBackground;
  backgroundImg2.resize(width, height);

  cardBackImg = currentTheme.cardBack;

  if (backgroundImg == null) {
    println("Erro ao carregar backgroundImg");
  }
  if (cardBackImg == null) {
    println("Erro ao carregar cardBackImg");
  }
}

void resetToMenu() {
  if (cards != null) cards.clear();

  firstCard = null;
  secondCard = null;
  lockInput = false;
  attempts = 0;
  score = 0;
  levelStartTime = 0;
  levelEndTime = -1;
  totalPausedTime = 0;
  levelBonusApplied = false;
  currentLevel = 0;
}

void draw() {
  if (gameState == MENU) {
    if (backgroundImg != null) {
      image(backgroundImg, 0, 0, width, height);
    } else {
      background(255);
    }
  } else {
    background(255);
  }

  switch (gameState) {
    case MENU:
      drawMenu();
      break;
    case PLAYING:
      drawPlaying();
      break;
    case PAUSED:
      drawPlaying();
      drawPauseMenu();
      break;
    case LEVEL_COMPLETE:
      drawLevelComplete();
      break;
    case GAME_OVER:
      drawGameOver();
      break;
    case GAME_COMPLETE:
      drawGameComplete();
      break;
  }

  if (lockInput && millis() - revealStartTime > 500) {
    if (firstCard != null) firstCard.hide();
    if (secondCard != null) secondCard.hide();
    firstCard = secondCard = null;
    lockInput = false;
  }
}

void drawPauseMenu() {
  fill(0, 150);
  rect(0, 0, width, height);

  int modalWidth = 300, modalHeight = 250;
  int modalX = width / 2 - modalWidth / 2;
  int modalY = height / 2 - modalHeight / 2;
  fill(255);
  rect(modalX, modalY, modalWidth, modalHeight, 10);

  fill(0);
  textSize(24);
  textAlign(CENTER, CENTER);
  text("Pausado", width / 2, modalY + 40);

  int btnWidth = 200, btnHeight = 40;
  int btnX = width / 2;
  int btnY = modalY + 80;

  fill(#3498DB);
  rectMode(CENTER);
  rect(btnX, btnY, btnWidth, btnHeight, 10);
  fill(255);
  textSize(20);
  text("Continuar", btnX, btnY);

  btnY += btnHeight + 20;
  fill(#3498DB);
  rect(btnX, btnY, btnWidth, btnHeight, 10);
  fill(255);
  text("Menu", btnX, btnY);

  btnY += btnHeight + 20;
  fill(#3498DB);
  rect(btnX, btnY, btnWidth, btnHeight, 10);
  fill(255);
  text("Sair", btnX, btnY);

  rectMode(CORNER);
}

//////////////////////////////
// MENU INICIAL
//////////////////////////////
void drawMenu() {
  background(backgroundImg);
  // Título
  noStroke();
  fill(0);
  textSize(36);
  textAlign(CENTER, CENTER);
  text("Jogo da Memória", width/2, height/8);
  
  int themeBtnWidth = 150;
  int themeBtnHeight = 40;
  int themeBtnX = width - themeBtnWidth - 20;
  int themeBtnY = 20;
  
  fill(#ED0239); 
  rect(themeBtnX, themeBtnY, themeBtnWidth, themeBtnHeight, 10);
  fill(255);
  textSize(16);
  textAlign(CENTER, CENTER);
  text("Tema: " + currentThemeName, themeBtnX + themeBtnWidth/2, themeBtnY + themeBtnHeight/2);
  
  // Caixa de entrada para o nome
  textSize(24);
  textAlign(CENTER, CENTER);
  fill(0);
  text("Player:", width/2, height/8 + 50);
  fill(#EBB09E);
  int inputWidth = 300, inputHeight = 40;
  rect(width/2 - inputWidth/2, height/8 + 70, inputWidth, inputHeight, 10);
  fill(0);
  textSize(20);
  text(playerName, width/2, height/8 + 70 + inputHeight/2);
  
  
  if (selectingTheme) {
  int tY = themeBtnY + themeBtnHeight + 10;
  for (String themeName : themes.keySet()) {
    fill(currentThemeName.equals(themeName) ? #ED0239 : #FF7E73);
    rect(themeBtnX, tY, themeBtnWidth, themeBtnHeight, 10);
    fill(255);
    text(themeName, themeBtnX + themeBtnWidth/2, tY + themeBtnHeight/2);
    tY += themeBtnHeight + 5;
  }
  }
  
  // Selecione o modo
  textSize(24);
  fill(0);
  text("Selecione o modo", width/2, height/8 + 140);
  
  // Botões dos modos (horizontal)
  int modeBtnWidth = 180, modeBtnHeight = 50;
  int modeBtnY = height/8 + 170;
  int modeBtnX1 = width/2 - modeBtnWidth - 10;
  int modeBtnX2 = width/2 + 10;
  
  fill((gameMode == MODE_PROGRESSIVO) ? #ED0239 : #FF7E73);
  rect(modeBtnX1, modeBtnY, modeBtnWidth, modeBtnHeight, 10);
  fill(255);
  textSize(18);
  text("Modo progressivo", modeBtnX1 + modeBtnWidth/2, modeBtnY + modeBtnHeight/2);
  
  fill((gameMode == MODE_INDIVIDUAL) ? #ED0239 : #FF7E73);
  rect(modeBtnX2, modeBtnY, modeBtnWidth, modeBtnHeight, 10);
  fill(255);
  text("Modo individual", modeBtnX2 + modeBtnWidth/2, modeBtnY + modeBtnHeight/2);
  
  // Se o modo Individual estiver selecionado, exibe as opções de dificuldade verticalmente
  int iniciarY;
  if (gameMode == MODE_INDIVIDUAL) {
    textSize(24);
    fill(0);
    text("Selecione a dificuldade:", width/2, modeBtnY + modeBtnHeight + 40);
    
    int diffBtnWidth = 200, diffBtnHeight = 40;
    int diffBtnX = width/2 - diffBtnWidth/2;
    int diffBtnY = modeBtnY + modeBtnHeight + 70;
    
    fill((currentLevel == 0) ? #ED0239 : #FF7E73);
    rect(diffBtnX, diffBtnY, diffBtnWidth, diffBtnHeight, 10);
    fill(255);
    textSize(18);
    text("Fácil", width/2, diffBtnY + diffBtnHeight/2);
    
    diffBtnY += diffBtnHeight + 10;
    fill((currentLevel == 1) ? #ED0239 : #FF7E73);
    rect(diffBtnX, diffBtnY, diffBtnWidth, diffBtnHeight, 10);
    fill(255);
    text("Médio", width/2, diffBtnY + diffBtnHeight/2);
    
    diffBtnY += diffBtnHeight + 10;
    fill((currentLevel == 2) ? #ED0239 : #FF7E73);
    rect(diffBtnX, diffBtnY, diffBtnWidth, diffBtnHeight, 10);
    fill(255);
    text("Difícil", width/2, diffBtnY + diffBtnHeight/2);
    
    iniciarY = diffBtnY + diffBtnHeight + 40;
  } else {
    iniciarY = height - 100;
    currentLevel = 0;
  }
  
  fill(#F0691F);
  rectMode(CENTER);
  rect(width/2, iniciarY, 150, 50, 10);
  fill(255);
  textSize(20);
  text("Iniciar", width/2, iniciarY);
  rectMode(CORNER);
}

//////////////////////////////
// JOGO EM ANDAMENTO
//////////////////////////////
void drawPlaying() {
  background(backgroundImg2);
  // Desenha as cartas do grid
  for (Card card : cards) {
    card.display();
  }

  // ==== Indicadores: Tentativas, Score, Tempo ====
  int elapsedTime = (millis() - levelStartTime) - totalPausedTime;
  int timeLeft = (gameState == PAUSED) 
    ? LEVEL_TIME_LIMITS[currentLevel] - ((pauseStartTime - levelStartTime) - totalPausedTime)
    : max(LEVEL_TIME_LIMITS[currentLevel] - elapsedTime, 0);
  String timeText = nf(timeLeft / 1000) + "s";

  if (timeLeft == 0) {
    gameState = GAME_OVER;
  }

  // UI layout
  int uiMargin = 20;
  int iconSize = 30;
  int spacing = 10;
  int textYOffset = iconSize / 2;

  fill(0);
  textSize(20);
  textAlign(LEFT, CENTER);

  // Tentativas
  int y = uiMargin;
  if (attemptsIcon != null) image(attemptsIcon, uiMargin, y, iconSize, iconSize);
  text(attempts + " / " + MAX_ATTEMPTS[currentLevel], uiMargin + iconSize + spacing, y + textYOffset);

  // Score
  y += iconSize + spacing;
  if (scoreIcon != null) image(scoreIcon, uiMargin, y, iconSize, iconSize);
  text(str(score), uiMargin + iconSize + spacing, y + textYOffset);

  // Tempo (canto superior direito)
  int timeX = width - uiMargin - iconSize;
  if (timeIcon != null) image(timeIcon, timeX, uiMargin, iconSize, iconSize);
  textAlign(RIGHT, CENTER);
  text(timeText, timeX - spacing, uiMargin + textYOffset);

  // ==== Verificações de estado ====

  // Se todas as cartas foram combinadas, congela o timer e muda para tela de nível concluído
  if (allCardsMatched()) {
    if (levelEndTime == -1) {
      levelEndTime = millis();
    }
    gameState = LEVEL_COMPLETE;
  }

  // Tempo esgotado
  if (timeLeft == 0 && gameState == PLAYING) {
    gameState = GAME_OVER;
  }

  // Tentativas esgotadas
  if (attempts > MAX_ATTEMPTS[currentLevel]) {
    gameState = GAME_OVER;
  }
}

//////////////////////////////
// TELA DE NÍVEL CONCLUÍDO
//////////////////////////////
void drawLevelComplete() {
  background(levelbackgroundImg);
  fill(0, 200);
  rect(0, 0, width, height);
  
  fill(255);
  textSize(36);
  textAlign(CENTER, CENTER);
  text("Parabéns, " + playerName + "!", width/2, height/3);
  
  int levelTime = min(levelEndTime - levelStartTime - totalPausedTime, LEVEL_TIME_LIMITS[currentLevel]);
  // Aplica bônus apenas uma vez
  if (!levelBonusApplied) {
    int totalPairs = cards.size()/2;
    int extraAttempts = attempts - 0; // Aqui somente erros contam
    int bonus = max((totalPairs * 100) - int((levelTime/1000.0)*5) - (extraAttempts*20), 0);
    score += bonus;
    levelBonusApplied = true;
  }
  
  textSize(24);
  text("Erros: " + attempts, width/2, height/2);
  text("Tempo: " + nf(levelTime/1000) + "s", width/2, height/2 + 40);
  text("Pontuação: " + score, width/2, height/2 + 80);
  
  // Botão para avançar
  fill(#3498DB);
  rectMode(CENTER);
  rect(width/2, height - 100, 200, 50, 10);
  fill(255);
  textSize(20);
  text((gameMode == MODE_PROGRESSIVO) ? 
       ((currentLevel < LEVELS.length-1) ? "Próximo Nível" : "Finalizar Jogo") : 
       "Voltar ao Menu", width/2, height - 100);
  rectMode(CORNER);
}

//////////////////////////////
// TELA DE GAME OVER (excesso de tentativas)
//////////////////////////////
void drawGameOver() {
  fill(0, 200);
  rect(0, 0, width, height);
  
  fill(255, 100, 100);
  textSize(36);
  textAlign(CENTER, CENTER);
  text("Game Over!", width/2, height/3);
  textSize(24);
  text("Tentativas: " + attempts, width/2, height/3 + 40);
  
  // Se for modo progressivo, exibe dois botões: "Jogar Novamente" e "Voltar ao Menu"
  if (gameMode == MODE_PROGRESSIVO) {
    int btnWidth = 200, btnHeight = 50;
    int btnY = height - 100;
    int btnY2 = height - 180;
    int btnX = width/2 + 10;
    
    fill(#3498DB);
    rectMode(CENTER);
    rect(btnX, btnY2, btnWidth, btnHeight, 10);
    rect(btnX, btnY, btnWidth, btnHeight, 10);
    
    fill(255);
    textSize(20);
    text("Jogar Novamente", btnX, btnY2);
    text("Voltar ao Menu", btnX, btnY);
    rectMode(CORNER);
  } else {
    // No modo Individual, apenas "Voltar ao Menu"
    fill(#3498DB);
    rectMode(CENTER);
    rect(width/2, height - 100, 200, 50, 10);
    fill(255);
    textSize(20);
    text("Voltar ao Menu", width/2, height - 100);
    rectMode(CORNER);
  }
}

//////////////////////////////
// TELA FINAL (após os níveis em modo progressivo ou se individual e finalizar)
//////////////////////////////
void drawGameComplete() {
  fill(0, 200);
  rect(0, 0, width, height);
  
  fill(255);
  textSize(36);
  textAlign(CENTER, CENTER);
  text("Parabéns, " + playerName + "!", width/2, height/4);
  textSize(28);
  text("Pontuação Final: " + score, width/2, height/4 + 40);
  
  // Mostra o ranking dos jogadores (ordenado por pontuação decrescente)
  textSize(24);
  text("Ranking:", width/2, height/2);
  for (int i = 0; i < ranking.size(); i++) {
    RankingEntry re = ranking.get(i);
    text((i+1) + ". " + re.name + " - " + re.score, width/2, height/2 + 30 + i*30);
  }
  
  // Botão para finalizar o jogo
  fill(#3498DB);
  rectMode(CENTER);
  rect(width/2, height - 100, 200, 50, 10);
  fill(255);
  textSize(20);
  text("Finalizar", width/2, height - 100);
  rectMode(CORNER);
}

//////////////////////////////
// INÍCIO DE UM NOVO NÍVEL
//////////////////////////////
void startNewLevel(int level) {
  int spacing = 10;
  int maxGridWidth = width - 2 * CARD_MARGIN;
  int maxGridHeight = height - 2 * CARD_MARGIN;
  
  levelStartTime = millis();
  totalPausedTime = 0;
  cards.clear();
  currentLevel = level;
  surface.setTitle("Jogo da Memória - " + LEVEL_NAMES[level]);

  int cols = LEVELS[level][0];
  int rows = LEVELS[level][1];
  int totalPairs = (cols * rows) / 2;

  Theme currentTheme = themes.get(currentThemeName);

  if (currentTheme.cardImages.size() < totalPairs) {
    println("Tema não possui imagens suficientes para esse nível.");
    resetToMenu();
    gameState = MENU;
    return;
  }

  ArrayList<PImage> selectedImages = currentTheme.getShuffledPairs(totalPairs);

  int cardSizeW = (maxGridWidth - spacing * (cols - 1)) / cols;
  int cardSizeH = (maxGridHeight - spacing * (rows - 1)) / rows;
  int cardSize = min(cardSizeW, cardSizeH);

  int gridWidth = cols * cardSize + spacing * (cols - 1);
  int gridHeight = rows * cardSize + spacing * (rows - 1);

  int startX = (width - gridWidth) / 2;
  int startY = (height - gridHeight) / 2;

for (int r = 0; r < rows; r++) {
  for (int c = 0; c < cols; c++) {
    int x = startX + c * (cardSize + spacing);
    int y = startY + r * (cardSize + spacing);
    
    // Pegando diretamente da lista embaralhada
    PImage img = selectedImages.remove(0);
    cards.add(new Card(x, y, cardSize, img));
  }
}
  // Redimensiona a imagem de fundo do verso uma única vez
  cardBackImg.resize(cardSize, cardSize);
  cardBackRounded = createRoundedImage(cardBackImg, 10);

  firstCard = secondCard = null;
  lockInput = false;
  attempts = 0;
  levelBonusApplied = false;
  levelEndTime = -1;
}


//////////////////////////////
// MANIPULAÇÃO DE CLIQUES
//////////////////////////////
void mousePressed() {
   if (gameState == MENU) {
    int inputWidth = 300, inputHeight = 40;
    int inputX = width/2 - inputWidth/2;
    int inputY = height/8 + 70;

    if (mouseX > inputX && mouseX < inputX + inputWidth &&
        mouseY > inputY && mouseY < inputY + inputHeight) {
      nameEntered = true;
    } else {
      nameEntered = false;
    }

    // Clique no botão principal de tema
    int themeBtnWidth = 150;
    int themeBtnHeight = 40;
    int themeBtnX = width - themeBtnWidth - 20;
    int themeBtnY = 20;

    if (mouseX > themeBtnX && mouseX < themeBtnX + themeBtnWidth &&
        mouseY > themeBtnY && mouseY < themeBtnY + themeBtnHeight) {
      selectingTheme = !selectingTheme; // abre ou fecha dropdown
      return;
    }

    // Se o dropdown está aberto, checa se clicou em algum tema
    if (selectingTheme) {
      int tY = themeBtnY + themeBtnHeight + 10;
      for (String themeName : themes.keySet()) {
        if (mouseX > themeBtnX && mouseX < themeBtnX + themeBtnWidth &&
            mouseY > tY && mouseY < tY + themeBtnHeight) {
          applyTheme(themeName);
          loadAssets(); // recarrega imagens
          selectingTheme = false;
          return;
        }
        tY += themeBtnHeight + 5;
      }
    }

    // Botões de modo
    int modeBtnWidth = 180, modeBtnHeight = 50;
    int modeBtnY = height/8 + 170;
    int modeBtnX1 = width/2 - modeBtnWidth - 10;
    int modeBtnX2 = width/2 + 10;

    if (mouseX > modeBtnX1 && mouseX < modeBtnX1 + modeBtnWidth &&
        mouseY > modeBtnY && mouseY < modeBtnY + modeBtnHeight) {
      gameMode = MODE_PROGRESSIVO;
    }
    if (mouseX > modeBtnX2 && mouseX < modeBtnX2 + modeBtnWidth &&
        mouseY > modeBtnY && mouseY < modeBtnY + modeBtnHeight) {
      gameMode = MODE_INDIVIDUAL;
    }

    // Se modo Individual, verifica botões de dificuldade
    if (gameMode == MODE_INDIVIDUAL) {
      int diffBtnWidth = 200, diffBtnHeight = 40;
      int diffBtnX = width/2 - diffBtnWidth/2;
      int diffBtnY = modeBtnY + modeBtnHeight + 70;

      if (mouseX > diffBtnX && mouseX < diffBtnX + diffBtnWidth &&
          mouseY > diffBtnY && mouseY < diffBtnY + diffBtnHeight) {
        currentLevel = 0;
      }
      diffBtnY += diffBtnHeight + 10;
      if (mouseX > diffBtnX && mouseX < diffBtnX + diffBtnWidth &&
          mouseY > diffBtnY && mouseY < diffBtnY + diffBtnHeight) {
        currentLevel = 1;
      }
      diffBtnY += diffBtnHeight + 10;
      if (mouseX > diffBtnX && mouseX < diffBtnX + diffBtnWidth &&
          mouseY > diffBtnY && mouseY < diffBtnY + diffBtnHeight) {
        currentLevel = 2;
      }

      int iniciarY = diffBtnY + diffBtnHeight + 40;
      if (mouseX > width/2 - 75 && mouseX < width/2 + 75 &&
          mouseY > iniciarY - 25 && mouseY < iniciarY + 25 && playerName.length() > 0) {
        score = 0;
        startNewLevel(currentLevel);
        gameState = PLAYING;
      }
    } else {
      int iniciarY = height - 100;
      if (mouseX > width/2 - 75 && mouseX < width/2 + 75 &&
          mouseY > iniciarY - 25 && mouseY < iniciarY + 25 && playerName.length() > 0) {
        score = 0;
        currentLevel = 0;
        startNewLevel(currentLevel);
        gameState = PLAYING;
      }
    }
    return;
  }
  
  // Se estiver no modo de jogo
 if (gameState == PLAYING) {
    if (allCardsMatched()) {
      checkNextButtonClick();
      return;
    }
    if (lockInput) return;
    for (Card card : cards) {
      if (card.isMouseOver()) {
        handleCardClick(card);
        break;
      }
    }
    return;
  }
  
   // Se o jogo está pausado, trata os cliques no modal de pausa
  if (gameState == PAUSED) {
    // Janela modal centralizada
    int modalWidth = 300, modalHeight = 250;
    int modalX = width/2 - modalWidth/2;
    int modalY = height/2 - modalHeight/2;
    
    // Botões da janela
    int btnWidth = 200, btnHeight = 40;
    int btnX = width/2;
    int btnY_cont = modalY + 80;       // "Continuar"
    int btnY_menu = btnY_cont + btnHeight + 20;  // "Menu"
    int btnY_exit = btnY_menu + btnHeight + 20;    // "Sair"
    
    if (mouseY > btnY_cont - btnHeight/2 && mouseY < btnY_cont + btnHeight/2) {
      int pauseDuration = millis() - pauseStartTime;
      totalPausedTime += pauseDuration; // Acumula o tempo pausado
      gameState = PLAYING;
    }
    
    if (mouseX > btnX - btnWidth/2 && mouseX < btnX + btnWidth/2) {
      if (mouseY > btnY_cont - btnHeight/2 && mouseY < btnY_cont + btnHeight/2) {
        // Retoma o jogo
        gameState = PLAYING;
      } else if (mouseY > btnY_menu - btnHeight/2 && mouseY < btnY_menu + btnHeight/2) {
         resetToMenu();
        gameState = MENU;
      } else if (mouseY > btnY_exit - btnHeight/2 && mouseY < btnY_exit + btnHeight/2) {
        exit();
      }
    }
    return;
  }
  
  // Se estiver na tela de nível completo ou game over, trata os botões
  if (gameState == LEVEL_COMPLETE) {
    checkNextButtonClick();
    return;
  }
  
  //GAMEOVER
if (gameState == GAME_OVER) {
    if (gameMode == MODE_PROGRESSIVO) {
      int btnWidth = 200, btnHeight = 50;
      int btnY_jogar = height - 180;  // "Jogar Novamente"
      int btnY_menu = height - 100;     // "Voltar ao Menu"
      int btnX = width/2;             // Centralizado
      if (mouseX > btnX - btnWidth/2 && mouseX < btnX + btnWidth/2 &&
          mouseY > btnY_jogar - btnHeight/2 && mouseY < btnY_jogar + btnHeight/2) {
        startNewLevel(currentLevel);
        gameState = PLAYING;
      } else if (mouseX > btnX - btnWidth/2 && mouseX < btnX + btnWidth/2 &&
                 mouseY > btnY_menu - btnHeight/2 && mouseY < btnY_menu + btnHeight/2) {
         resetToMenu();
        gameState = MENU;
      }
    } else { // Modo Individual
      int btnY = height - 100;
      if (mouseX > width/2 - 100 && mouseX < width/2 + 100 &&
          mouseY > btnY - 25 && mouseY < btnY + 25) {
             resetToMenu();
        gameState = MENU;
      }
    }
    return;
  }
 if (gameState == GAME_COMPLETE) {
    // Agora com duas opções: "Finalizar" e "Voltar ao Menu"
    int btnWidth = 200, btnHeight = 50;
    int btnY_final = height - 180; // "Finalizar" botão
    int btnY_menu = height - 100;  // "Voltar ao Menu"
    int btnX = width/2;
    if (mouseX > btnX - btnWidth/2 && mouseX < btnX + btnWidth/2) {
      if (mouseY > btnY_final - btnHeight/2 && mouseY < btnY_final + btnHeight/2) {
        exit();
      } else if (mouseY > btnY_menu - btnHeight/2 && mouseY < btnY_menu + btnHeight/2) {
         resetToMenu();
        gameState = MENU;
      }
    }
    return;
  }
}

void keyPressed() {
   if (key == ESC) {
  key = 0;
  if (gameState == PLAYING) {
    gameState = PAUSED;
    pauseStartTime = millis();  // marca quando começou a pausa
  } else if (gameState == PAUSED) {
    gameState = PLAYING;
    totalPausedTime += millis() - pauseStartTime;  // acumula tempo pausado
  }
}
  if (gameState == MENU && nameEntered) {
    if (key == BACKSPACE) {
      if (playerName.length() > 0)
        playerName = playerName.substring(0, playerName.length()-1);
    } else if (key == ENTER || key == RETURN) {
      nameEntered = false;
    } else {
      playerName += key;
    }
  }
  // Se estiver jogando, aperta Esc para pausar
  if (gameState == PLAYING && key == ESC) {
    key = 0;  // Evita que o Processing feche o sketch
    gameState = PAUSED;
  }
  // Se estiver pausado, o Esc pode também retomar o jogo (opcional)
}

void handleCardClick(Card card) {
  if (card.matched || card.revealed) return;

  card.reveal();

  if (firstCard == null) {
    firstCard = card;
  } else {
    secondCard = card;
    if (firstCard.img == secondCard.img) {
      firstCard.match();
      secondCard.match();
      score += 100;
      firstCard = secondCard = null;
    } else {
      attempts++;
      lockInput = true;
      revealStartTime = millis();
    }
  }
}

void checkNextButtonClick() {
  // Botão nas telas de nível completo ou game over
  if (mouseX > width/2 - 100 && mouseX < width/2 + 100 &&
      mouseY > height - 125 && mouseY < height - 75) {
    if (gameState == LEVEL_COMPLETE) {
      if (gameMode == MODE_PROGRESSIVO) {
        if (currentLevel < LEVELS.length-1) {
          startNewLevel(currentLevel + 1);
          gameState = PLAYING;
        } else {
          // Último nível: adiciona ao ranking e finaliza o jogo
          ranking.add(new RankingEntry(playerName, score));
          gameState = GAME_COMPLETE;
        }
      } else {
        // No modo individual, após terminar um nível, volta para o menu
         resetToMenu();
        gameState = MENU;
      }
    }
  }
}

boolean allCardsMatched() {
  for (Card card : cards) {
    if (!card.matched) return false;
  }
  return !cards.isEmpty();
}
  PImage createRoundedImage(PImage img, float radius) {
  PGraphics mask = createGraphics(img.width, img.height);
  mask.beginDraw();
  mask.background(0);
  mask.fill(255);
  mask.noStroke();
  mask.rect(0, 0, img.width, img.height, radius);
  mask.endDraw();

  PImage result = img.copy();
  result.mask(mask.get());
  return result;
}
//////////////////////////////
// CLASSE CARTA
//////////////////////////////
class Card {
  float x, y, size;
  boolean revealed = false;
  boolean matched = false;
  PImage img;

  Card(int x, int y, int size, PImage img) {
   this.x = x;
    this.y = y;
    this.size = size;
    this.img = img;
  }
 
  
void display() {
  stroke(50);
  strokeWeight(2);

  if (matched) {
    fill(MATCHED_COLOR);
    rect(x, y, size, size, CARD_ROUNDING);
    imageMode(CENTER);
    image(img, x + size/2, y + size/2, size * 0.8, size * 0.8);

  } else if (revealed) {
    fill(REVEALED_COLOR);
    rect(x, y, size, size, CARD_ROUNDING);
    imageMode(CENTER);
    image(img, x + size/2, y + size/2, size * 0.8, size * 0.8);

  } else {
    fill(CARD_COLOR);
    rect(x, y, size, size, CARD_ROUNDING);
    imageMode(CENTER);
    image(cardBackRounded, x + size/2, y + size/2, size * 0.95, size * 0.95);
  }
  noStroke();
}

  boolean isMouseOver() {
    return mouseX > x && mouseX < x + size && mouseY > y && mouseY < y + size;
  }

  void reveal() {
    revealed = true;
  }

  void hide() {
    revealed = false;
  }

  void match() {
    matched = true;
  }
   boolean isMatch(Card other) {
    return this.img == other.img;
  }
}
void generateCards(int level, Theme theme) {
  cards.clear();

  int cols = LEVELS[level][0];
  int rows = LEVELS[level][1];
  int totalPairs = (cols * rows) / 2;
  ArrayList<PImage> images = theme.getShuffledPairs(totalPairs);

  // Calcula tamanho das cartas e centraliza o grid
  int availableWidth = width - 2 * CARD_MARGIN;
  int availableHeight = height - 100; // Espaço para UI no topo
  int cardSize = min(availableWidth / cols, availableHeight / rows);
  int gridX = (availableWidth - cols * cardSize) / 2 + CARD_MARGIN;
  int gridY = (availableHeight - rows * cardSize) / 2 + 80; // Espaço para UI

  ArrayList<Integer> indices = new ArrayList<Integer>();
  for (int i = 0; i < totalPairs; i++) {
    indices.add(i);
    indices.add(i); // Para pares
  }
  Collections.shuffle(indices);

  for (int row = 0; row < rows; row++) {
    for (int col = 0; col < cols; col++) {
      int x = gridX + col * cardSize;
      int y = gridY + row * cardSize;

      int index = indices.remove(0);
      PImage cardImg = images.get(index);
      cards.add(new Card(x, y, cardSize, cardImg));
    }
  }
}

class Theme {
  String name;
  ArrayList<PImage> cardImages;
  PImage cardBack;
  PImage menuBackground;
  PImage playingBackground;
  PImage levelCompleteBackground;

  Theme(String name, String[] imagePaths, String cardBackPath, String menuBG, String playBG, String levelBG) {
    this.name = name;
    cardImages = new ArrayList<PImage>();
    for (String path : imagePaths) {
      cardImages.add(loadImage(path));
    }
    cardBack = loadImage(cardBackPath);
    menuBackground = loadImage(menuBG);
    playingBackground = loadImage(playBG);
    levelCompleteBackground = loadImage(levelBG);
  }

  ArrayList<PImage> getShuffledPairs(int pairCount) {
    ArrayList<PImage> available = new ArrayList<PImage>(cardImages);
    Collections.shuffle(available);

    if (available.size() < pairCount) {
      println("Erro: Tema '" + name + "' não possui imagens suficientes para " + pairCount + " pares.");
      return new ArrayList<PImage>();
    }

    ArrayList<PImage> selected = new ArrayList<PImage>();
    for (int i = 0; i < pairCount; i++) {
      PImage img = available.get(i);
      selected.add(img);
      selected.add(img);
    }

    Collections.shuffle(selected);
    return selected;
  }
}
