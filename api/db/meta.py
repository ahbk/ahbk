from typing import AsyncGenerator

from sqlalchemy.ext.asyncio import AsyncSession, AsyncAttrs, async_sessionmaker, create_async_engine
from sqlalchemy.orm import DeclarativeBase
from ahbk_api.config import settings

class Base(AsyncAttrs, DeclarativeBase):
    pass

echo = settings.log_level in ['debug', 'trace']
engine = create_async_engine(settings.db_uri, echo=echo)
async_session = async_sessionmaker(engine, expire_on_commit=False)

async def get_async_session() -> AsyncGenerator[AsyncSession, None]:
    async with async_session() as session:
        yield session
