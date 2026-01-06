# LoggerPro Contrib Appenders

This folder contains appenders that have **external dependencies** and are not included in the main LoggerPro package.

To use these appenders, you need to:
1. Install the required dependencies
2. Add this folder to your project's search path
3. Include the appender unit in your project

## Available Appenders

### LoggerPro.RedisAppender

Sends log messages to a Redis list.

**Dependencies:**
- [DelphiRedisClient](https://github.com/danieleteti/delphiredisclient) - Available via GetIt or GitHub

**Required units from DelphiRedisClient:**
- `Redis.Client`
- `Redis.Values`
- `Redis.Command`
- `Redis.Commons`
- `Redis.NetLib.INDY`
- `Redis.NetLib.Factory`

**Usage:**
```delphi
uses
  LoggerPro,
  LoggerPro.RedisAppender;

var
  Log: ILogWriter;
begin
  Log := BuildLogWriter([
    TLoggerProRedisAppender.Create('localhost', 6379, 1000)
  ]);
end;
```

**Sample:** See `90_remote_logging_with_redis` folder for a complete example.
