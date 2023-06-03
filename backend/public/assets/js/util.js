/*global fetch*/

const postDB = async (url, body, fnc) => {
  try {
    const request_body = JSON.stringify(body) 
    
    await fetch(url, {
      method: 'POST',
      headers: {
        "Content-Type": "application/json"
      },
      body: request_body
    })
    .then(res=>res.json())
    .then(data=>fnc(data))
  } catch (error) {
    console.log(error);
  }
};