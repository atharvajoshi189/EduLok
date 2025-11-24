import sentencepiece as spm
import os

model_path = r'c:\Projects\eduthon\assets\ai\sentencepiece.model'
output_path = r'c:\Projects\eduthon\assets\ai\vocab.txt'

if not os.path.exists(model_path):
    print(f"Error: Model not found at {model_path}")
    exit(1)

try:
    sp = spm.SentencePieceProcessor()
    sp.load(model_path)

    with open(output_path, 'w', encoding='utf-8') as f:
        for id in range(sp.get_piece_size()):
            piece = sp.id_to_piece(id)
            score = sp.get_score(id)
            # Format: token <tab> id <tab> score
            f.write(f"{piece}\t{id}\t{score}\n")

    print(f"Successfully exported {sp.get_piece_size()} tokens to {output_path}")
except Exception as e:
    print(f"Error exporting vocab: {e}")
