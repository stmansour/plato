from sqlalchemy import create_engine
import pymysql
import pandas as pd

user = "ec2-user"
pw = ""
host = "localhost"
port = 3306
# dburl = 'mysql://{0}:{1}@{2}:{3}'.format(user, pw, host, port)
dburl = 'mysql+pymysql://ec2-user@localhost:3306'
sqlEngine = create_engine(dburl)
# sqlEngine = create_engine('mysql+pymysql://ec2-user@localhost:3306')
cnx    = sqlEngine.connect()

MaxItems = 10000
DtStart = "2021-09-01"
DtStop = "2021-11-15"
q = 'SELECT Title,IID FROM plato.Item WHERE "{}" <= PubDt AND PubDt < "{}" LIMIT {};'.format(DtStart,DtStop,MaxItems)

frame = pd.read_sql(q, cnx);

pd.set_option('display.expand_frame_repr', False)
print(frame)

cnx.close()
