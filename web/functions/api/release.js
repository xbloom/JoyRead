// Cloudflare Pages Function - 获取最新 Release
export async function onRequest(context) {
  const GITHUB_REPO = 'xbloom/JoyRead';
  
  try {
    // 从 GitHub API 获取最新 release
    const response = await fetch(
      `https://api.github.com/repos/${GITHUB_REPO}/releases/latest`,
      {
        headers: {
          'User-Agent': 'JoyRead-Download-Page'
        }
      }
    );
    
    if (!response.ok) {
      throw new Error('Failed to fetch release');
    }
    
    const data = await response.json();
    const ipaAsset = data.assets.find(asset => asset.name.endsWith('.ipa'));
    
    if (!ipaAsset) {
      throw new Error('IPA file not found');
    }
    
    // 返回简化的数据
    const result = {
      version: data.tag_name,
      size: ipaAsset.size,
      downloadUrl: `https://ghproxy.net/${ipaAsset.browser_download_url}`,
      directUrl: ipaAsset.browser_download_url,
      publishedAt: data.published_at
    };
    
    return new Response(JSON.stringify(result), {
      headers: {
        'Content-Type': 'application/json',
        'Cache-Control': 'public, max-age=300' // 缓存 5 分钟
      }
    });
    
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        status: 500,
        headers: { 'Content-Type': 'application/json' }
      }
    );
  }
}
