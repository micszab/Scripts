#!/bin/bash

board=(1 2 3 4 5 6 7 8 9)
player="X"
computer="O"

print_menu(){
    echo ""
    echo "1. New game"
    echo "2. Load game"
    echo "3. Exit"
    echo ""
}

print_board() {
    echo ""
    echo " ${board[0]} | ${board[1]} | ${board[2]} "
    echo "---|---|---"
    echo " ${board[3]} | ${board[4]} | ${board[5]} "
    echo "---|---|---"
    echo " ${board[6]} | ${board[7]} | ${board[8]} "
    echo ""
}

save_game() {
    echo "Save current status to: "; read -r save_file
    echo "${board[@]}" > $save_file
    echo "$player" >> $save_file
    echo "Game saved to $save_file"
}

load_game() {
    echo "Enter save file name: "; read -r save_file
    if [[ -f $save_file ]]; then
        read -a board < $save_file
        player=$(tail -n 1 "$save_file")
        echo "$player"
        board=("${board[@]:0:9}")
        echo "Game loaded"
    else
        echo "File is not existing"
    fi
}

check_draw() {
    for field in "${board[@]}"; do
        if [[ "$field" != "X" && "$fied" != "O" ]]; then
            return 1
        fi
    done
    echo "Draw!"
    return 0
}

check_win() {
    local sets=("0 1 2" "3 4 5" "6 7 8" "0 3 6" "1 4 7" "2 5 8" "0 4 8" "2 4 6")
    local b=("${board[@]}")
    
    for set in "${sets[@]}"; do
        local i=($set)
        if [[ "${b[${i[0]}]}" == "${b[${i[1]}]}" ]] && \
        [[ "${b[${i[1]}]}" == "${b[${i[2]}]}" ]]; then
            echo "${b[${i[0]}]} win!"
            return 0
        fi
    done
    return 1
}

computer_move() {
    local move
    while :; do
        move=$((RANDOM % 9))
        if [[ "${board[$move]}" != "X"]] && [["${board[$move]}" != "O" ]]; then
            board[$move]=$computer
            break
        fi
    done
}

play_game() {
    print_board
    while :; do
        if [[ "$player" == "X" ]]; then
            echo "Your turn press (1-9) or 'S' to save game:"
            read -r move
            if [[ "$move" == "s" ]]; then
                save_game
                continue
            elif [[ "$move" =~ ^[1-9]$ ]] && \
                [[ "${board[$((move-1))]}" != "X" ]] && \
                [[ "${board[$((move-1))]}" != "O" ]]; then
                board[$((move-1))]=$player
            else
                echo "Incorrect movement!"
                continue
            fi
        else
            computer_move
            echo "Computer has made a move"
        fi

        print_board

        if check_win; then
            break
        elif check_draw; then
            break
        fi

        if [[ "$player" == "X" ]]; then
            player=$computer
        else
            player="X"
        fi
    done
}

main(){
    while :; do
        print_menu
        read -r choice
        case $choice in
            1)
                play_game
                ;;
            2)
                load_game
                play_game
                ;;
            3)
                break
                ;;
            *)
                echo "Incorrect choice!"
                ;;
        esac
    done
}

main