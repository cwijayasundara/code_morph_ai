import warnings
from dotenv import load_dotenv
from langchain.chains.conversation.base import ConversationChain
from langchain.memory import ConversationBufferMemory
from langchain_openai import ChatOpenAI
import tiktoken

warnings.filterwarnings('ignore')
_ = load_dotenv()

model_name = "gpt-4o-mini"

encoding = tiktoken.encoding_for_model(model_name)

# Initialize the chat model and memory
llm = ChatOpenAI(model_name=model_name,
                  temperature=0,
                  max_tokens=100)

query = ("Whats AdS/CFT correspondence? Explain in no less than 500 tokens and when the generation is complete, "
         "output the word *END* as well.")

memory = ConversationBufferMemory(return_messages=True)
conversation = ConversationChain(llm=llm, memory=memory)

response = conversation.predict(input=query)

full_response = response

while "*END*" not in response:
    continuation_prompt = "Continue from where you left off"
    continuation_response = conversation.predict(input=continuation_prompt)
    full_response += " " + continuation_response
    response = continuation_response


full_response_tokens = len(encoding.encode(full_response))

print("final response", full_response)
print("final response tokens", full_response_tokens)