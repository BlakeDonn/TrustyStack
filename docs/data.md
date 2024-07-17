## Databases

### PostgreSQL Setup

1. **Install PostgreSQL**:
    ```bash
    sudo apt update
    sudo apt install postgresql postgresql-contrib
    ```

2. **Start PostgreSQL Service**:
    ```bash
    sudo service postgresql start
    ```

3. **Create a Database and User**:
    ```bash
    sudo -i -u postgres
    psql
    CREATE DATABASE mydb;
    CREATE USER myuser WITH ENCRYPTED PASSWORD 'mypassword';
    GRANT ALL PRIVILEGES ON DATABASE mydb TO myuser;
    \q
    exit
    ```

### MongoDB Setup

1. **Install MongoDB**:
    ```bash
    wget -qO - https://www.mongodb.org/static/pgp/server-4.4.asc | sudo apt-key add -
    echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/4.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.4.list
    sudo apt update
    sudo apt install -y mongodb-org
    ```

2. **Start MongoDB Service**:
    ```bash
    sudo systemctl start mongod
    sudo systemctl enable mongod
    ```

3. **Configure Rust Backend to Connect to Databases**:
    - Create Database Connection Module in `db.rs`:
        ```rust
        use tokio_postgres::{NoTls, Client};
        use mongodb::{Client as MongoClient, options::ClientOptions};

        pub async fn connect_postgres() -> Client {
            let (client, connection) =
                tokio_postgres::connect("host=localhost user=myuser password=mypassword dbname=mydb", NoTls)
                    .await
                    .unwrap();

            tokio::spawn(async move {
                if let Err(e) = connection.await {
                    eprintln!("connection error: {}", e);
                }
            });

            client
        }

        pub async fn connect_mongodb() -> MongoClient {
            let mut client_options = ClientOptions::parse("mongodb://localhost:27017").await.unwrap();
            client_options.app_name = Some("My App".to_string());
            MongoClient::with_options(client_options).unwrap()
        }
        ```
