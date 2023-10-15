from ahbk_api.models import Greeting
from db.meta import async_session
import sqlalchemy as sa

async def get_greeting():
    statement = sa.select(Greeting).limit(1).order_by(Greeting.id.desc())

    async with async_session() as session:
        async with session.begin():
            result = await session.scalars(statement)
            return result.one()

async def app(scope, receive, send):
    assert scope['type'] == 'http'
    greeting = await get_greeting()
    print('asdf')

    await send({
        'type': 'http.response.start',
        'status': 200,
        'headers': [
            [b'content-type', b'text/plain'],
        ],
    })
    await send({
        'type': 'http.response.body',
        'body': greeting.phrase.encode('utf-8'),
    })

def run():
    import uvicorn
    from ahbk_api.config import settings
    uvicorn.run(
            'ahbk_api.main:app',
            port=8000,
            reload=settings.env == 'dev',
            log_level=settings.log_level,
            )


if __name__=='__main__':
    run()
