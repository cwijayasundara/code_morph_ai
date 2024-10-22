import os
import magika
from pathlib import Path

m = magika.Magika()

def extract_code(repo_dir):
    code_index=[]
    file_list = []
    code_text=""
    for root, _, files in os.walk(repo_dir):

        for file in files:
            file_path = os.path.join(root, file)
            relative_path = os.path.relpath(file_path, repo_dir)
            code_index.append(relative_path)
            file_type = m.identify_path(Path(file_path))

            if file_type.output.group in ["text", "code"]:
                try:
                    with open(file_path, "r") as f:
                        code_text += f"__________{relative_path}__________\n"
                        code_text += f.read()
                        code_text += "\n\n"
                        file_list.append(code_text)
                except Exception:
                    pass
    return code_index, code_text, file_list

def get_code_prompt(question, code_index, code_text):

    """ generate a prompt for code related questions """

    prompt = f"""
    Question : {question}
    
    Context:
    
    - Entire codebase is provided below.
    - Here is an index of the files in the codebase: {code_index}
    - Each file is concatenated togather and provided below. {code_text}
    
    Answer:

    """

    return prompt

# test
# repo_dir = "./code"
# code_index, code_text, file_content = extract_code(repo_dir)
# for file in file_content:
#     print(file)