from kafka import KafkaProducer
from datetime import datetime
import time

#topic = 'asdf3'
topic = 'f5-telemetry'

datetime_obj = datetime.now().strftime('%Y-%m-%d %H:%M:%S')

print(datetime_obj)

producer = KafkaProducer(bootstrap_servers='znw-linapp1018.statoil.no:9092')
string = bytes(datetime_obj, encoding='utf-8')

future = producer.send(topic, b'START :  ' + string)
result = future.get(timeout=1)

print(result)


for i in range(2):
    time.sleep(1)
    datetime_obj = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    datetime_obj = datetime.now().strftime('%M:%S')
    string = bytes(datetime_obj, encoding='utf-8')
    future = producer.send(topic, b'onsdag ' + string)
    result = future.get(timeout=1)
    print(i)
    print(result)