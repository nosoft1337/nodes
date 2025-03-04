#!/bin/bash
channel_logo() {
  echo -e '\e[31m'
  cat << "EOF"
                      ______    __                                                          
                     /      \  /  |                                                         
  _______   ______  /$$$$$$  |_$$ |_     ______    ______    ______   ______   _____  ____  
 /       | /      \ $$ |_ $$// $$   |   /      \  /      \  /      \ /      \ /     \/    \ 
/$$$$$$$/ /$$$$$$  |$$   |   $$$$$$/   /$$$$$$  |/$$$$$$  |/$$$$$$  |$$$$$$  |$$$$$$ $$$$  |
$$      \ $$ |  $$ |$$$$/      $$ | __ $$ |  $$ |$$ |  $$ |$$ |  $$/ /    $$ |$$ | $$ | $$ |
 $$$$$$  |$$ \__$$ |$$ |       $$ |/  |$$ \__$$ |$$ \__$$ |$$ |     /$$$$$$$ |$$ | $$ | $$ |
/     $$/ $$    $$/ $$ |       $$  $$/ $$    $$/ $$    $$ |$$ |     $$    $$ |$$ | $$ | $$ |
$$$$$$$/   $$$$$$/  $$/         $$$$/   $$$$$$/   $$$$$$$ |$$/       $$$$$$$/ $$/  $$/  $$/ 
                                                 /  \__$$ |                                 
                                                 $$    $$/                                  
                                                  $$$$$$/                                   
EOF
  echo -e '\e[39m'
  echo -e "\n\nПодпишись на канал в крипте @softogram1337 [💸]"
}

download_node() {
  echo 'Начинаю установку...'

  read -p "Введите ваш приватный ключ: " PRIVATE_KEY
  echo $PRIVATE_KEY > $HOME/my.pem

  session="hyperspacenode"

  cd $HOME

  sudo apt-get update -y && sudo apt-get upgrade -y
  sudo apt-get install wget make tar screen nano build-essential unzip lz4 gcc git jq -y

  if [ -d "$HOME/.aios" ]; then
    sudo rm -rf "$HOME/.aios"
    aios-cli kill
  fi
  
  if screen -list | grep -q "\.${session}"; then
    screen -S hyperspacenode -X quit
  else
    echo "Сессия ${session} не найдена."
  fi

  while true; do
    curl -s https://download.hyper.space/api/install | bash | tee $HOME/hyperspacenode_install.log

    if ! grep -q "Failed to parse version from release data." $HOME/hyperspacenode_install.log; then
        echo "Клиент-скрипт был установлен."
        break
    else
        echo "Сервер установки клиента недоступен, повторим через 30 секунд..."
        sleep 30
    fi
  done

  rm hyperspacenode_install.log

  export PATH=$PATH:$HOME/.aios
  source ~/.bashrc

  eval "$(cat ~/.bashrc | tail -n +10)"

  screen -dmS hyperspacenode bash -c '
    echo "Начало выполнения скрипта в screen-сессии"

    aios-cli start

    exec bash
  '

  while true; do
    aios-cli models add hf:TheBloke/phi-2-GGUF:phi-2.Q4_K_M.gguf 2>&1 | tee $HOME/hyperspacemodel_download.log

    if grep -q "Download complete" $HOME/hyperspacemodel_download.log; then
        echo "Модель была установлен."
        break
    else
        echo "Сервер установки модели недоступен, повторим через 30 секунд..."
        sleep 30
    fi
  done

  rm hyperspacemodel_download.log

  aios-cli hive import-keys $HOME/my.pem
  aios-cli hive login
  aios-cli hive connect
}

check_logs() {
  screen -S hyperspacenode -X hardcopy /tmp/screen_log.txt && sleep 0.1 && tail -n 100 /tmp/screen_log.txt && rm /tmp/screen_log.txt
}

check_points() {
  aios-cli hive points
}

restart_node() {
  session="hyperspacenode"
  
  if screen -list | grep -q "\.${session}"; then
    screen -S "${session}" -p 0 -X stuff "^C"
    sleep 1
    screen -S "${session}" -p 0 -X stuff "aios-cli start --connect\n"
    echo "Нода была перезагружена."
  else
    echo "Сессия ${session} не найдена."
  fi
}

delete_node() {
  read -p 'Если уверены удалить ноду, введите любую букву (CTRL+C чтобы выйти): ' checkjust

  echo 'Начинаю удалять ноду...'

  screen -S hyperspacenode -X quit
  aios-cli kill
  aios-cli models remove hf:TheBloke/phi-2-GGUF:phi-2.Q4_K_M.gguf
  sudo rm -rf $HOME/.aios

  echo 'Нода была удалена.'
}

exit_from_script() {
  exit 0
}

while true; do
    channel_logo
    sleep 2
    echo -e "\n\nМеню:"
    echo "1. 🙂 Установить ноду"
    echo "2. 📜 Посмотреть логи"
    echo "3. ⭐ Узнать сколько поинтов"
    echo "4. 🔄 Перезагрузить ноду"
    echo "5. 🗑️ Удалить ноду"
    echo -e "6. 🚪 Выйти из скрипта\n"
    read -p "Выберите пункт меню: " choice

    case $choice in
      1)
        download_node
        ;;
      2)
        check_logs
        ;;
      3)
        check_points
        ;;
      4)
        restart_node
        ;;
      5)
        delete_node
        ;;
      6)
        exit_from_script
        ;;
      *)
        echo "Неверный пункт. Пожалуйста, выберите правильную цифру в меню."
        ;;
    esac
  done
