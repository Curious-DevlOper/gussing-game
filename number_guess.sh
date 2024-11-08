#!/bin/bash

# Define the PSQL variable to execute SQL commands
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# Generate the random secret number between 1 and 1000
SECRET_NUMBER=$((RANDOM % 1000 + 1))

# Prompt user for username
echo "Enter your username:"
read USERNAME

# Check if the username is no longer than 22 characters
if [[ ${#USERNAME} -gt 22 ]]; then
  echo "Username must be 22 characters or less."
  exit 1
fi

# Check if the user exists in the database
USER_INFO=$($PSQL "SELECT user_id, games_played, best_game FROM users WHERE username='$USERNAME'")

if [[ -z $USER_INFO ]]; then
  # If user does not exist, insert a new record
  echo "Welcome, $USERNAME! It looks like this is your first time here."
  INSERT_USER_RESULT=$($PSQL "INSERT INTO users(username) VALUES('$USERNAME')")
else
  # If user exists, greet the user and show stats
  IFS="|" read USER_ID GAMES_PLAYED BEST_GAME <<< "$USER_INFO"
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

# Initialize guess count and prompt user to start guessing
echo "Guess the secret number between 1 and 1000:"
NUMBER_OF_GUESSES=0

while true; do
  read GUESS

  # Check if the input is an integer
  if ! [[ $GUESS =~ ^[0-9]+$ ]]; then
    echo "That is not an integer, guess again:"
    continue
  fi

  # Increment guess count
  NUMBER_OF_GUESSES=$((NUMBER_OF_GUESSES + 1))

  # Check if the guess is correct, high, or low
  if [[ $GUESS -eq $SECRET_NUMBER ]]; then
    echo "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"
    break
  elif [[ $GUESS -gt $SECRET_NUMBER ]]; then
    echo "It's lower than that, guess again:"
  else
    echo "It's higher than that, guess again:"
  fi
done

# If user was new, retrieve the new user ID for record keeping
if [[ -z $USER_INFO ]]; then
  USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$USERNAME'")
fi

# Update user statistics
# Increment games_played
UPDATE_GAMES_PLAYED_RESULT=$($PSQL "UPDATE users SET games_played = games_played + 1 WHERE user_id = $USER_ID")

# Update best_game if this game has fewer guesses than the best_game or if it is the first game
if [[ -z $BEST_GAME || $NUMBER_OF_GUESSES -lt $BEST_GAME ]]; then
  UPDATE_BEST_GAME_RESULT=$($PSQL "UPDATE users SET best_game = $NUMBER_OF_GUESSES WHERE user_id = $USER_ID")
fi

# Record the game in the games table
INSERT_GAME_RESULT=$($PSQL "INSERT INTO games(user_id, guesses) VALUES($USER_ID, $NUMBER_OF_GUESSES)")
