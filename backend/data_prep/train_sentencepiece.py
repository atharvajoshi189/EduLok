import sentencepiece as spm
spm.SentencePieceTrainer.Train('--input=vocab.txt --model_prefix=labse_sp --vocab_size=30000 --model_type=unigram')
