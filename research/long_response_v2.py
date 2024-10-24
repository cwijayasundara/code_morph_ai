import warnings
from dotenv import load_dotenv
from langchain.chains.conversation.base import ConversationChain
from langchain.memory import ConversationBufferMemory
from langchain_openai import ChatOpenAI

warnings.filterwarnings('ignore')
_ = load_dotenv()

# Initialize the chat model and memory
chat = ChatOpenAI(model_name="gpt-4o-2024-08-06", temperature=0, max_tokens=500)

memory = ConversationBufferMemory(return_messages=True)
conversation = ConversationChain(llm=chat, memory=memory)

# Initial prompt
user_input = ("Explain the theory of general relativity in detail, including its historical development, "
              "mathematical formulations, experimental confirmations, and implications for modern physics.")

# Generate the initial response
response = conversation.predict(input=user_input)

# Initialize the full response
full_response = response

# Check if continuation is needed
max_tokens = 500
needs_continuation = len(response.split()) >= max_tokens - 50

while needs_continuation:
    # Prompt the model to continue
    continuation_prompt = "Continue from where you left off"

    # Generate the continuation response
    continuation_response = conversation.predict(input=continuation_prompt)

    # Append the continuation to the full response
    full_response += " " + continuation_response

    # Check again if the continuation is also truncated
    needs_continuation = len(continuation_response.split()) >= max_tokens - 50

# Output the full response
print("Full Response:\n", full_response)