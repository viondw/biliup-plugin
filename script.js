const CACHE_TTL = 5 * 60 * 1000; // 5分钟，单位为毫秒
let lastCacheTime = 0;
let cachedData = null;

// GitHub API endpoint to fetch repository content
const apiUrl = 'https://api.github.com/repos/viondw/biliup-plugin/contents';

// Function to fetch and display folder list
async function displayFolderList() {
    try {
        // Check if cache is valid
        if (Date.now() - lastCacheTime < CACHE_TTL && cachedData) {
            console.log('Using cached data');
            renderFolderList(cachedData);
            return;
        }

        const response = await fetch(apiUrl);
        const data = await response.json();

        // Update cache
        lastCacheTime = Date.now();
        cachedData = data;

        renderFolderList(data);
    } catch (error) {
        console.error('Error fetching data: ', error);
    }
}

async function renderFolderList(data) {
    const folderList = document.getElementById('folderList');
    folderList.innerHTML = ''; // Clear previous content

    for (const item of data) {
        if (item.type === 'dir') {
            const card = document.createElement('a');
            card.classList.add('resource-card');
            card.href = item.html_url;
            card.target = "_blank";
            card.rel = "noreferrer";

            const header = document.createElement('div');
            header.classList.add('resource-card-header');

            const title = document.createElement('div');
            title.classList.add('resource-card-header-title');

            const text = document.createElement('div');
            text.classList.add('resource-card-header-text');
            text.textContent = item.name;

            const avatar = document.createElement('div');
            avatar.classList.add('resource-card-header-avatar');
            avatar.innerHTML = `<img src="https://img2.imgtp.com/2024/05/20/x91K9Arw.png" alt="avatar">`;

            title.appendChild(text);
            header.appendChild(title);
            header.appendChild(avatar);

            card.appendChild(header);

            const desc = document.createElement('div');
            desc.classList.add('resource-card-desc');
            
            try {
                const descResponse = await fetch(`${item.url}/说明.txt`);
                if (descResponse.ok) {
                    const descText = await descResponse.text();
                    desc.textContent = descText;
                } else {
                    desc.textContent = '';
                }
            } catch (error) {
                desc.textContent = '';
            }

            const footer = document.createElement('div');
            footer.classList.add('resource-card-footer');

            const footerInfo = document.createElement('div');
            footerInfo.classList.add('resource-card-footer-info');

            footer.appendChild(footerInfo);

            card.appendChild(desc);
            card.appendChild(footer);

            folderList.appendChild(card);
        }
    }
}

// Periodically refresh data
setInterval(displayFolderList, CACHE_TTL);
displayFolderList(); // Initial load