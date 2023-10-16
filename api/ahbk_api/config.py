from os import getenv

class Settings():
    secret_key: str = str(getenv('secret_key'))
    db_uri: str = str(getenv('db_uri'))
    log_level: str = str(getenv('log_level'))
    env: str = str(getenv('env'))
    api_home: str = str(getenv('api_home'))


if getenv('log_level') == None:
    raise TypeError('yo, source .env')

settings = Settings()
assert settings.env == 'prod'

if settings.env == 'prod':
    assert getenv('secret_key') is not None
    with open(str(getenv('secret_key')), encoding="utf-8") as f:
        settings.secret_key = f.read()

print(f"Log level: {settings.log_level}")
print(settings.secret_key)
