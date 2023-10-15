from sqlalchemy import String
from sqlalchemy.orm import Mapped
from sqlalchemy.orm import mapped_column

from db.meta import Base

class Greeting(Base):
    __tablename__ = "greeting"
    id: Mapped[int] = mapped_column(primary_key=True)
    phrase: Mapped[str] = mapped_column(String(30))
    def __repr__(self) -> str:
        return f"Greeting(id={self.id!r}, phrase={self.phrase!r})"

