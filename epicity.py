import tkinter as tk
from tkinter import Button
from PIL import ImageGrab, Image
import numpy as np
import tensorflow as tf
from tensorflow.keras.preprocessing import image
import json
import openai
import io
from stability_sdk import client
import stability_sdk.interfaces.gooseai.generation.generation_pb2 as generation
import os

def on_draw(event):
    brush_size = 1
    canvas.create_oval(event.x - brush_size, 
                    event.y - brush_size, 
                    event.x + brush_size, 
                    event.y + brush_size, 
                    fill='black', outline='black')

def load_and_prepare_image_from_canvas(canvas, img_size=(224, 224), save_path='canvas_image.png'):
    canvas.update_idletasks()

    if os.path.exists(save_path):
        os.remove(save_path)

    x = root.winfo_rootx() + canvas.winfo_x()
    y = root.winfo_rooty() + canvas.winfo_y()
    x1 = x + canvas.winfo_width()
    y1 = y + canvas.winfo_height()

    if x1 <= x or y1 <= y:
        raise ValueError("Invalid crop dimensions.")

    img = ImageGrab.grab(bbox=(x, y, x1, y1))

    if img is None or img.size == (0, 0):
        raise ValueError("Captured image is invalid.")

    img.save(save_path)
    img = img.convert('RGB')
    img = img.resize(img_size, Image.Resampling.LANCZOS)
    img_array = np.array(img)
    img_array = img_array.astype('float32')
    img_array_expanded_dims = np.expand_dims(img_array, axis=0)
    return tf.keras.applications.efficientnet.preprocess_input(img_array_expanded_dims)


def decode_predictions(predictions, top=3, dataset_path='./dataset'):
    class_names = sorted([dI for dI in os.listdir(dataset_path) if os.path.isdir(os.path.join(dataset_path,dI))])
    results = []
    for pred in predictions:
        top_indices = pred.argsort()[-top:][::-1]
        result = [(class_names[i], pred[i]) for i in top_indices]
        results.append(result)
    return results

def generate_description(word):
    prompt = f"""Generate a text prompt suitable for an image generation tool that captures the essence of a singular "{word}".
    **Style:** : random
    **Focus:** : random
    * Include specific characteristics relevant to "{word}" to enhance the visual representation.
    * Consider incorporating elements like lighting, texture, and composition.
    * Setting: Briefly describe the environment surrounding the "{word}".
    * Mood: Specify the desired mood or atmosphere.
    * Color palette: (Optional) Mention specific colors or color combinations."""
    response = openai.Completion.create(
        engine="gpt-3.5-turbo-instruct",  
        prompt=prompt,
        temperature=0.7,
        max_tokens=100,
        top_p=1.0,
        frequency_penalty=0.0,
        presence_penalty=0.0
    )
    return response.choices[0].text.strip()

def generate_image_from_prompt(prompt):
    try:
        answers = stability_api.generate(
            prompt=prompt,
            seed=np.random.randint(np.iinfo(np.int32).max),
            steps=50,
            cfg_scale=8.0,
            width=1024,
            height=1024,
            samples=1,
        )
        for resp in answers:
            for artifact in resp.artifacts:
                if artifact.type == generation.ARTIFACT_IMAGE:
                    img_data = io.BytesIO(artifact.binary)
                    img = Image.open(img_data)
                    img.show()
    except Exception as e:
        print(f"Error in generating image: {e}")

with open('config.json') as config_file:
    config = json.load(config_file)
openai.api_key = config["OPENAI_API_KEY"]
STABILITY_KEY = config['STABILITY_KEY']

stability_api = client.StabilityInference(
    key=STABILITY_KEY,
    verbose=True,
    engine="stable-diffusion-xl-1024-v1-0",
)

model_path = './models/doodle_recognition'
loaded_model = tf.saved_model.load(model_path)
infer = loaded_model.signatures["serving_default"]

def generate():
    prepared_image = load_and_prepare_image_from_canvas(canvas)
    pred_logits = infer(tf.constant(prepared_image))['dense'].numpy()
    top_predictions = decode_predictions(pred_logits, top=3)
    for predicted_class, _ in top_predictions[0]:
        description = generate_description(predicted_class)
        print(f"Generated description for {predicted_class}: {description}")
        generate_image_from_prompt(description)



root = tk.Tk()
root.title("Doodle")
canvas_width = 224
canvas_height = 224
canvas = tk.Canvas(root, width=canvas_width, height=canvas_height, bg='white')
canvas.pack()
canvas.bind('<B1-Motion>', on_draw)

button = Button(root, text="Generate", command=generate)
button.pack()

root.mainloop()
