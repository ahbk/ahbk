import asyncio
from ahbk_api.models import Greeting
from db.meta import async_session
import sqlalchemy as sa


async def run():
    async with async_session() as session:
        async with session.begin():
            greeting = await get_greeting(session)
            print(greeting)

async def get_greeting(session):
    statement = sa.select(Greeting).limit(1).order_by(Greeting.id.desc())
    result = await session.scalars(statement)
    r = result.one()

    if(r):
        return r.phrase
    else:
        greeting = Greeting(phrase="Hello world!")
        session.add(greeting)
        await session.commit()
        return greeting.phrase

asyncio.run(run())
