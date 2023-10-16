import asyncio
from ahbk_api.models import Greeting
from db.meta import async_session
import sqlalchemy as sa
from alembic.config import Config
from alembic import command
from ahbk_api.config import settings
from sqlalchemy.exc import NoResultFound

def run():
    migrate()
    asyncio.run(populate())

def migrate():
    alembic_cfg = Config(settings.api_home + "alembic.ini")
    alembic_cfg.set_main_option('script_location',
                                settings.api_home + 'alembic/');
    alembic_cfg.set_main_option('sqlalchemy.url', settings.db_uri);
    command.upgrade(alembic_cfg, "head")

async def populate():
    async with async_session() as session:
        async with session.begin():
            greeting = await get_greeting(session)
            print(greeting)

async def get_greeting(session):
    statement = sa.select(Greeting).limit(1).order_by(Greeting.id.desc())
    result = await session.scalars(statement)

    try:
        r = result.one()
        return r.phrase
    except NoResultFound:
        greeting = Greeting(phrase="Hello world!")
        session.add(greeting)
        await session.commit()
        return greeting.phrase
