from typing import List
from typing import Optional
from sqlalchemy import ForeignKey
from sqlalchemy import String
from sqlalchemy.orm import DeclarativeBase
from sqlalchemy.orm import Mapped
from sqlalchemy.orm import mapped_column
from sqlalchemy.orm import relationship

from db.meta import Base

class User(Base):
    __tablename__ = "user"
    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String(30))
    password: Mapped[Optional[str]]
    def __repr__(self) -> str:
        return f"User(id={self.id!r}, name={self.name!r}, password={self.password!r})"
