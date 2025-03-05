# importing pandas to perform automation
import pandas as pd
from sqlalchemy import create_engine

# storing the database loocation into variable
conn_string = 'postgresql://postgres:admin@localhost/paintings'

# creating a engine
db = create_engine(conn_string)

# storing newly created db connection into a variable
conn = db.connect()

# 1. database can be created by passing csv files  
# # creating a dataframe to read data present in csv files
# df = pd.read_csv(f'\\Users\\admin\\Downloads\\TFQ-SQL Practice set\SQL Case Study – Art & Museum Data Analysis/artist.csv')

# # printing data 
# print(df.info)

# # loading data which was stored earlier in df dataframe to sql database
# # syntax - df.to_sql('table name', connection, if_exists = "replace"/"fail"/"append", index = True/False)
# df.to_sql('artist', con = conn, if_exists = 'replace', index = False)


# 2. using for loop
# creating a list of csv files
files = ['museum', 'museum_hours', 'product_size', 'subject', 'work', 'artist', 'canvas_size', 'image_link']
for file in files:
    df = pd.read_csv(f'\\Users\\admin\\Downloads\\TFQ-SQL Practice set\SQL Case Study – Art & Museum Data Analysis/{file}.csv')
    df.to_sql(file, con = conn, if_exists = 'replace', index = False)
