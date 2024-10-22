from dotenv import load_dotenv
from langchain_anthropic import ChatAnthropic
from langchain_openai import ChatOpenAI
from util import extract_code, get_code_prompt
import streamlit as st
from prompt_templates import code_explain_prompt, java_code_gen_prompt, oo_design_prompt
from langchain_core.prompts import PromptTemplate

_ = load_dotenv()

code_dir_name = "./code"

llm_anthropic = ChatAnthropic(model="claude-3-5-sonnet-20240620", temperature=0.1)

llm_openai = ChatOpenAI(model="gpt-4o",temperature=0.1)

llm_openai_mini = ChatOpenAI(model="gpt-4o-mini", temperature=0.1)

llm_openai_o1 = ChatOpenAI(model="o1-preview", temperature=1.0)

code_index, code_text, file_content = extract_code(code_dir_name)

llm=None

st.title("/CodeMorph_AI")

st.markdown(
    """
    <style>
        section[data-testid="stSidebar"] {
            width: 500px !important; # Set the width to your desired value
        }
    </style>
    """,
    unsafe_allow_html=True,
)

with st.sidebar:
    st.title("/CodeMorph_AI")
    st.image("image/legacy_mod.jpeg", width=500)

    select_llm = st.radio(
        "Select the Language Model",
        ("/openai_gpt_4o_mini",
         "/openai_gpt_4o",
         "/openai_o1_preview",
         "/claude_3.5_sonnet")
    )

    if select_llm == "/openai_gpt_4o_mini":
        llm = llm_openai_mini
        st.write("Selected Language Model:", llm.model_name)
    elif select_llm == "/openai_gpt_4o":
        llm = llm_openai
        st.write("Selected Language Model:", llm.model_name)
    elif select_llm == "/openai_o1_preview":
        llm = llm_openai_o1
        st.write("Selected Language Model:", llm.model_name)
    elif select_llm == "/claude_3.5_sonnet":
        llm = llm_anthropic
        st.write("Selected Language Model:", llm.model)

    add_radio = st.radio(
        "What can I do for you today?",
        ("/show_code",
         "/command_interface",
         "/explain",
         "/generate_oo_design",
         "/generate_java_code")
    )

def execute(exec_llm, exec_prompt, code):
    final_prompt = PromptTemplate.from_template(exec_prompt)
    exec_chain = final_prompt | exec_llm
    final_response = exec_chain.invoke(
        {
            "PLSQL_CODE": code,
        }
    )
    return final_response.content

if add_radio== "/show_code":
    st.title("/show_code")
    st.write("Here is the index of the files in the codebase:")
    st.write(code_index)
    st.write("Here is the entire codebase:")
    st.code(code_text)

elif add_radio == "/command_interface":
    st.title("/command_interface")
    question = st.text_input("Enter your question here:")
    if st.button("/get_answer"):
        prompt = get_code_prompt(question, code_index, code_text)
        response = llm.invoke(prompt)
        st.write(response.content)

elif add_radio == "/explain":
    st.title("/explain")
    for file in file_content:
        print("content of the file is: ", file)
        response = execute(llm, code_explain_prompt, file)
        st.write(response)

elif add_radio == "/generate_oo_design":
    st.title("/generate_oo_design")
    response = execute(llm, oo_design_prompt, code_text)
    st.write(response)

elif add_radio == "/generate_java_code":
    st.title("/generate_java_code")
    for file in file_content:
        response = execute(llm, java_code_gen_prompt, file)
        st.write(response)



