from auth import user
import asyncio
import asyncpg

def _test_db_connection():
    async def run():
        conn = await asyncpg.connect(user='frans', port=5433)
        values = await conn.fetch(
                'SELECT * FROM frans WHERE id = $1',
                10,
                )
        await conn.close()
    loop = asyncio.get_event_loop()
    loop.run_until_complete(run())

def test_create_user():
    assert user.create('asdf', 'asdf') == None

