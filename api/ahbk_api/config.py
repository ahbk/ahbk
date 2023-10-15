from os import getenv

class Settings():
    secret_key: str = str(getenv('secret_key'))
    db_uri: str = str(getenv('db_uri'))
    log_level: str = str(getenv('log_level'))
    env: str = str(getenv('env'))


try:
    settings = Settings()
    print(f"Log level: {settings.log_level}")
except TypeError:
    print('yo, source .env')
    import sys
    sys.exit(0)
