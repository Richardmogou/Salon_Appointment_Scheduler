#!/bin/bash

PSQL="psql -X --username=postgres --dbname=salon --tuples-only -c"

echo -e "\n~~~~~ Welcome to My Salon ~~~~~\n"

# Main menu function to display available services
MAIN_MENU() {
  if [[ $1 ]]; then
    echo -e "\n$1"
  fi

  echo "List of services we offer:"

  # Retrieve list of services
  SERVICES=$($PSQL "SELECT service_id, name FROM services ORDER BY service_id;")

  # Display services with proper formatting (with space after closing parenthesis)
   
  echo "$SERVICES" | while IFS=' |' read SERVICE_ID SERVICE_NAME; 
  do
    # Display service ID and name with space after parenthesis
    echo "$SERVICE_ID) $(echo $SERVICE_NAME )"
  done

  echo -e "\nPlease select a service by entering the corresponding number:"
  read SERVICE_ID_SELECTED

  # Check if the selected service exists
  SERVICE_NAME=$($PSQL "SELECT name FROM services WHERE service_id = $SERVICE_ID_SELECTED;" | sed 's/^ *//;s/ *$//')

  if [[ -z $SERVICE_NAME ]]; then
    MAIN_MENU "Invalid service selection. Please try again."
  else
    echo "You selected: $SERVICE_NAME"
    handle_customer $SERVICE_ID_SELECTED "$SERVICE_NAME"
  fi
}

# Function to handle customer information and appointment
handle_customer() {
  SERVICE_ID_SELECTED=$1
  SERVICE_NAME=$2

  echo -e "\nPlease enter your phone number:"
  read CUSTOMER_PHONE

  # Retrieve customer name based on phone number
  CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE phone = '$CUSTOMER_PHONE';" | sed 's/^ *//;s/ *$//')

  if [[ -z $CUSTOMER_NAME ]]; then
    echo "It seems you are a new customer. What's your name?"
    read CUSTOMER_NAME

    # Insert new customer into the database
    INSERT_CUSTOMER_RESULT=$($PSQL "INSERT INTO customers (name, phone) VALUES ('$CUSTOMER_NAME', '$CUSTOMER_PHONE');")
  fi

  echo -e "\nWelcome, $CUSTOMER_NAME. What time would you like for your $SERVICE_NAME?"
  read SERVICE_TIME

  # Retrieve customer ID
  CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone = '$CUSTOMER_PHONE';" | sed 's/^ *//;s/ *$//')

  # Insert the appointment into the database
  INSERT_APPOINTMENT=$($PSQL "INSERT INTO appointments (customer_id, service_id, time) VALUES ($CUSTOMER_ID, $SERVICE_ID_SELECTED, '$SERVICE_TIME');")

  echo -e "\nI have put you down for a $SERVICE_NAME at $SERVICE_TIME, $CUSTOMER_NAME."
}

# Call the main menu function to start the process
MAIN_MENU

