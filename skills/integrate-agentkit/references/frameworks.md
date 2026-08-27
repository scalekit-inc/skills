# Integrate AgentKit — framework samples

Not the default path. Finish connection → connected account → token → one HTTP call in `SKILL.md` first.

These helpers are Python-first in the Scalekit SDK. Install the framework packages. The Scalekit SDK alone is not enough.

`providers` is the connector type slug (`GMAIL`, `SLACK`, …). It is **not** the dashboard Connection Name used in `SKILL.md`.

For Node agents, stay on the token path or name `expose-agentkit-mcp`.

## LangChain

```bash
pip install scalekit-sdk-python langchain langchain-openai langchain-core
```

```python
from langchain_openai import ChatOpenAI
from langchain.agents import AgentExecutor, create_openai_tools_agent
from langchain_core.prompts import ChatPromptTemplate

tools = actions.langchain.get_tools(
    identifier="user_123",
    providers=["GMAIL"],
    page_size=100
)

prompt = ChatPromptTemplate.from_messages([
    ("system", "You are a helpful assistant with access to external tools."),
    ("placeholder", "{chat_history}"),
    ("human", "{input}"),
    ("placeholder", "{agent_scratchpad}"),
])

llm = ChatOpenAI(model="gpt-4o")
agent = create_openai_tools_agent(llm, tools, prompt)
executor = AgentExecutor(agent=agent, tools=tools, verbose=True)
result = executor.invoke({"input": "fetch my last 5 unread emails and summarize them"})
```

## Google ADK

```bash
# Package: https://pypi.org/project/google-adk/ (Google Agent Development Kit)
pip install scalekit-sdk-python google-adk
```

```python
from google.adk.agents import Agent

gmail_tools = actions.google.get_tools(
    providers=["GMAIL"],
    identifier="user_123",
    page_size=100
)

agent = Agent(
    name="gmail_assistant",
    model="gemini-2.5-flash",
    description="Gmail assistant that can read and manage emails",
    instruction="You are a helpful Gmail assistant that can read, send, and organize emails.",
    tools=gmail_tools
)

response = agent.process_request("fetch my last 5 unread emails and summarize them")
```

More framework patterns: https://docs.scalekit.com/agentkit/code-samples/
