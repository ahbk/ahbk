import alembic.config

def run():
    alembicArgs = [ '--raiseerr', 'upgrade', 'head' ]
    alembic.config.main(argv=alembicArgs)
