# שמור קובץ זה בשם: fingerprint_processor.py
import cv2
import numpy as np
import os
import argparse
from fingerprint_enhancer import enhance_fingerprint

def imread_unicode(path):
    """פונקציה עוקפת לקריאת תמונות מנתיב עם עברית"""
    # קריאת הקובץ כזרם של בייטים בעזרת numpy
    stream = np.fromfile(path, dtype=np.uint8)
    # פענוח הבייטים לתמונה בעזרת OpenCV
    # הדגל cv2.IMREAD_GRAYSCALE שווה ערך ל-0 (גווני אפור)
    return cv2.imdecode(stream, cv2.IMREAD_GRAYSCALE)

def imwrite_unicode(path, img):
    """פונקציה עוקפת לשמירת תמונות בנתיב עם עברית"""
    # קידוד התמונה לפורמט הרצוי (לפי סיומת הקובץ) בזיכרון
    ext = os.path.splitext(path)[1]
    is_success, im_buf = cv2.imencode(ext, img)
    
    if is_success:
        # שמירת הבייטים לקובץ בעזרת numpy
        im_buf.tofile(path)
        return True
    return False

# --- התחלת התוכנית ---
parser = argparse.ArgumentParser()
parser.add_argument('input_path', help='Path to input image')
args = parser.parse_args()

input_filename = args.input_path

if not os.path.exists(input_filename):
    print(f"Error: File {input_filename} not found.")
    exit(1)

try:
    # 1. טעינה (עם הפונקציה החדשה שתומכת בעברית)
    img = imread_unicode(input_filename)
    
    if img is None:
        raise Exception("Failed to decode image. File might be corrupted.")

    # 2. הקטנה לשיפור ביצועים
    height, width = img.shape
    max_width = 800
    if width > max_width:
        scaling_factor = max_width / float(width)
        new_height = int(height * scaling_factor)
        img = cv2.resize(img, (max_width, new_height), interpolation=cv2.INTER_AREA)

    # 3. עיבוד
    out = enhance_fingerprint(img)
    
    # 4. המרה לשחור לבן
    out = np.array(out, dtype=np.uint8) * 255

    # 5. יצירת שם קובץ פלט
    folder = os.path.dirname(input_filename)
    filename = os.path.basename(input_filename)
    name_no_ext = os.path.splitext(filename)[0]
    
    output_filename = os.path.join(folder, f"{name_no_ext}_enhanced.png")
    
    # 6. שמירה (עם הפונקציה החדשה שתומכת בעברית)
    success = imwrite_unicode(output_filename, out)
    
    if success:
        print(f"SUCCESS: {output_filename}")
    else:
        print("ERROR: Failed to save image via numpy workaround.")
        exit(1)

except Exception as e:
    # הדפסת השגיאה כדי ש-MATLAB יקלוט אותה
    print(f"ERROR: {e}")
    exit(1)