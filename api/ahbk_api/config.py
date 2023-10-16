from os import getenv

class Settings():
    secret_key: str = str(getenv('secret_key'))
    db_uri: str = str(getenv('db_uri'))
    log_level: str = str(getenv('log_level'))
    env: str = str(getenv('env'))
    api_home: str = str(getenv('api_home'))


try:
    if getenv('log_level') == None:
        raise TypeError
    settings = Settings()
    print(f"Log level: {settings.log_level}")
except TypeError:
    import sys
    sys.exit('yo, source .env')
