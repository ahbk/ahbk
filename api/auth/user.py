from ahbk_api.config import settings
from db.meta import session

def create(name, password):
    session(settings)
