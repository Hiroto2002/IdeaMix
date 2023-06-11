/*global fetch*/
/*global $*/

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

const requestGPT = async(url,body,fnc)=>{
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
    .then(data=>{
      fnc(JSON.parse(data.message));
      // fnc((data.message))
    })
  } catch (error) {
    console.log(error);
    fnc("error");
  }
};

const handleClickLike=(event,id)=>{
    event.stopPropagation(); 
    const count = $(`#${id} p`).text()
    const body = {id:Number(id),count:Number(count)}
    
    postDB("/like",body,(data)=>{
          $(`#${id} p`).text(data.count)
    })
}

const handlePushRouter=(url)=> {
    window.location.href = url;
}