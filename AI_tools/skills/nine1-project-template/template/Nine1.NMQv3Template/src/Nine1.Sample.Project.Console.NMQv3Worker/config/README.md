# Nine1 連線字串安全設定

如果有使用 `services.AddNine1SecretConnectionStringProvider<T>()` 的連線字串設定，需要使用下方的設定方式產生連線字串設定

## Database Secrets

透過設定 `settings.json` 以及增加 `secrets.db.*.json` 檔案，來符合安全規範

## 設定 settings.json

- 可以有多組 Mappings, 如果系統有使用一組以上的資料庫
- 預設名稱為 `Default`
- 每組 Mappings 設定，都需要對應到一個單一的 `secrets.db.*.json` 設定檔案
- `secrets.db.*.json` 內僅設定簡單的連線資訊，如 `Password` 或 `Host` 等資訊，其他的延伸屬性設定，可透過 `ExtendedProperties` 來設定

```json
{
    "_N1CONFIG": {
        "ConnectionStringMappings": {
            "Default": {
                "Database": "database1",
                "Username": "user1",
                "ExtendedProperties": {
                    "Maximun Pool Size": 100,
                    "Pooling": true,
                    "Search Path": "my_schema"
                }
            }
        }
    }
}
```

## 產生 secrets.db.*.json

- 檔名規則: `secrets.db.[Database].[Username].json`
- 以上方設定值內容，檔名為 `secrets.db.database1.user1.json`

### PostgreSQL 格式範例

連線字串: `Host=localhost;Database=postgres;Username=postgres;Password=guest;Port:5432`

> 若使用 AWS RDS 所產生出來的 AWS Secret (json 格式)，內容不會有 database 名稱，此時會使用 `settings.json` 內設定的 Database 當作資料庫名稱資訊填入

檔案內容：

```json
{
    "Host": "localhost",
    "Username": "postgres",
    "Password": "guest",
    "Port": 5432
}
```

### MSSQL 格式範例

連線字串: `User ID=*****;Password=*****;Initial Catalog=AdventureWorks;Server=MySqlServer`

檔案內容：  

```json
  {
    "Server": "MySqlServer",
    "Initial Catalog": "AdventureWorks",
    "User ID": "*****",
    "Password": "*****"
  }
```

## 使用 IConnectionStringProvider 

透過注入 `IConnectionStringProvider` 的物件來取得連線字串


```csharp
public class SampleService {

    public SampleService(IConnectionStringProvider provider) {

        var connectionString = provider.GetConnectionString("Default");
    }
}

```