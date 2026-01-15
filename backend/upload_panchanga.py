import firebase_admin
from firebase_admin import credentials, firestore
import pandas as pd

# 1. Initialize Firebase
cred = credentials.Certificate('serviceAccountKey.json')
firebase_admin.initialize_app(cred)
db = firestore.client()

def upload_data():
    # 2. Read the CSV
    df = pd.read_csv('panchanga.csv')
    
    # Rename columns to standard keys
    # Note: Using index-based selection to handle the "6.49 am" header issue
    df.columns = [
        'date', 'samvastara', 'aayana', 'rutu', 'masa', 'paksha', 
        'tithi', 'vasara', 'nakshatra', 'yoga', 'karana', 'sunrise', 'sunset'
    ]
    
    df['date'] = df['date'].astype(str)
    print(f"Starting upload of {len(df)} cleaned records...")

    batch = db.batch()
    count = 0

    for _, row in df.iterrows():
        doc_ref = db.collection('panchanga_data').document(row['date'])
        
        data = {
            'samvastara': str(row['samvastara']),
            'aayana': str(row['aayana']),
            'rutu': str(row['rutu']),
            'masa': str(row['masa']),
            'paksha': str(row['paksha']),
            'tithi': str(row['tithi']),
            'nakshatra': str(row['nakshatra']),
            'yoga': str(row['yoga']),
            'karana': str(row['karana']),
            'vasara': str(row['vasara']),
            'sunrise': str(row['sunrise']),
            'sunset': str(row['sunset'])
        }
        
        batch.set(doc_ref, data)
        count += 1

        if count % 400 == 0:
            batch.commit()
            batch = db.batch()
            print(f"Uploaded {count} records...")

    batch.commit()
    print(f"Success! {count} records updated with Sunrise/Sunset.")

if __name__ == "__main__":
    upload_data()